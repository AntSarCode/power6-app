import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:power6_mobile/config/api_constants.dart';
import 'package:power6_mobile/models/user.dart';
import 'package:power6_mobile/screens/subscription_screen.dart';
import 'package:power6_mobile/services/api_service.dart';
import 'package:power6_mobile/services/purchase_service.dart';
import 'package:power6_mobile/state/app_state.dart';

const accountToken = '6371eb08-157a-4392-ac54-9dfc7601e55b';
const member = User(
    id: 1,
    username: 'member',
    email: 'member@example.com',
    isAdmin: false,
    tier: 'free',
    streak: 0);

class TestStore implements InAppPurchase {
  final updates = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <String?>[];
  PurchaseParam? started;
  bool failCompletion = false;
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => updates.stream;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<ProductDetailsResponse> queryProductDetails(
          Set<String> identifiers) async =>
      ProductDetailsResponse(
          productDetails: identifiers
              .map((id) => ProductDetails(
                  id: id,
                  title: 'Plan',
                  description: 'Plan',
                  price: r'$5.00',
                  rawPrice: 5,
                  currencyCode: 'USD'))
              .toList(),
          notFoundIDs: []);
  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    started = purchaseParam;
    return true;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}
  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (failCompletion) throw StateError('store unavailable');
    completed.add(purchase.purchaseID);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PurchaseApi extends ApiService {
  PurchaseApi() : super('https://example.com');
  Completer<ApiResponse>? pending;
  ApiResponse? activationFailure;
  bool rejectAccountToken = false;
  Map<String, dynamic> verified = {...member.toJson(), 'tier': 'pro'};
  int activationCalls = 0;
  @override
  Future<ApiResponse> post(String path,
      {String? token,
      Map<String, dynamic>? body,
      Map<String, dynamic>? query}) async {
    if (path == ApiConstants.appleAccountToken) {
      return rejectAccountToken
          ? ApiResponse.failure('offline')
          : ApiResponse.success({'app_account_token': accountToken});
    }
    activationCalls++;
    return pending?.future ??
        Future.value(activationFailure ?? ApiResponse.success(verified));
  }
}

PurchaseDetails receipt(
        {PurchaseStatus status = PurchaseStatus.purchased,
        String product = 'power6_proM'}) =>
    PurchaseDetails(
        purchaseID: '1001',
        productID: product,
        transactionDate: '1',
        status: status,
        verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: 'provider-lookup-data',
            source: 'app_store'))
      ..pendingCompletePurchase = true;

Future<(AppState, TestStore, PurchaseApi)> open(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final app = AppState();
  await app.setAuthToken('member-token', user: member);
  final store = TestStore();
  final api = PurchaseApi();
  await tester.pumpWidget(ChangeNotifierProvider.value(
      value: app,
      child: MaterialApp(
          home: SubscriptionScreen(
              purchaseService: PurchaseService(inAppPurchase: store),
              apiService: api))));
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await store.updates.close();
    api.dispose();
    app.dispose();
  });
  return (app, store, api);
}

void appleTest(String name, WidgetTesterCallback callback) {
  testWidgets(name, callback,
      variant: TargetPlatformVariant({TargetPlatform.iOS}));
}

void main() {
  appleTest(
      'purchase remains free and unacknowledged until server verification',
      (tester) async {
    final (app, store, api) = await open(tester);
    api.pending = Completer<ApiResponse>();
    store.updates.add([receipt()]);
    await tester.pump();
    expect(app.user?.tier, 'free');
    expect(store.completed, isEmpty);
    api.pending!.complete(ApiResponse.success(api.verified));
    await tester.pumpAndSettle();
    expect(app.user?.tier, 'pro');
    expect(store.completed, ['1001']);
  });

  for (final failure in [
    'offline',
    'expired',
    'wrong owner',
    'not configured'
  ]) {
    appleTest(
        '$failure cannot grant access or acknowledge purchase; restore can retry',
        (tester) async {
      final (app, store, api) = await open(tester);
      api.activationFailure = ApiResponse.failure(failure);
      store.updates.add([receipt()]);
      await tester.pumpAndSettle();
      expect(app.user?.tier, 'free');
      expect(store.completed, isEmpty);
      expect(find.textContaining('could not verify'), findsOneWidget);
      api.activationFailure = null;
      store.updates.add([receipt(status: PurchaseStatus.restored)]);
      await tester.pumpAndSettle();
      expect(app.user?.tier, 'pro');
      expect(store.completed, ['1001']);
    });
  }

  appleTest(
      'late response after verification timeout cannot activate or acknowledge',
      (tester) async {
    final (app, store, api) = await open(tester);
    api.pending = Completer<ApiResponse>();
    store.updates.add([receipt()]);
    await tester.pump();
    await tester.pump(const Duration(seconds: 9));
    api.pending!.complete(ApiResponse.success(api.verified));
    await tester.pumpAndSettle();
    expect(app.user?.tier, 'free');
    expect(store.completed, isEmpty);
  });

  appleTest('response from a previous login cannot overwrite the new account',
      (tester) async {
    final (app, store, api) = await open(tester);
    api.pending = Completer<ApiResponse>();
    store.updates.add([receipt()]);
    await tester.pump();
    await app.setAuthToken('other-token', user: member.copyWith(id: 2));
    api.pending!.complete(ApiResponse.success(api.verified));
    await tester.pumpAndSettle();
    expect(app.user?.id, 2);
    expect(app.user?.tier, 'free');
    expect(store.completed, isEmpty);
  });

  appleTest('server response must belong to the signed-in account',
      (tester) async {
    final (app, store, api) = await open(tester);
    api.verified['id'] = 2;
    store.updates.add([receipt()]);
    await tester.pumpAndSettle();
    expect(app.user?.tier, 'free');
    expect(store.completed, isEmpty);
  });

  appleTest('queued duplicate callbacks are verified sequentially',
      (tester) async {
    final (app, store, api) = await open(tester);
    api.pending = Completer<ApiResponse>();
    store.updates.add([receipt()]);
    store.updates.add([receipt(status: PurchaseStatus.restored)]);
    await tester.pump();
    expect(api.activationCalls, 1);
    api.pending!.complete(ApiResponse.success(api.verified));
    await tester.pumpAndSettle();
    expect(api.activationCalls, 2);
    expect(app.user?.tier, 'pro');
  });

  for (final status in [
    PurchaseStatus.canceled,
    PurchaseStatus.pending,
    PurchaseStatus.error
  ]) {
    appleTest('$status never activates or completes a purchase',
        (tester) async {
      final (app, store, api) = await open(tester);
      store.updates.add([receipt(status: status)]);
      await tester.pump();
      await tester.pump(const Duration(seconds: 13));
      expect(app.user?.tier, 'free');
      expect(api.activationCalls, 0);
      expect(store.completed, isEmpty);
    });
  }

  appleTest('new purchase passes only the server-issued UUID to StoreKit',
      (tester) async {
    final (_, store, _) = await open(tester);
    final button = find.text(r'Monthly - $5.00').first;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(store.started?.applicationUserName, accountToken);
    await tester.pump(const Duration(seconds: 13));
  });

  appleTest('account-token preparation failure prevents a StoreKit purchase',
      (tester) async {
    final (_, store, api) = await open(tester);
    api.rejectAccountToken = true;
    final button = find.text(r'Monthly - $5.00').first;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(store.started, isNull);
  });

  appleTest(
      'failed store acknowledgement keeps verified access and offers retry',
      (tester) async {
    final (app, store, _) = await open(tester);
    store.failCompletion = true;
    store.updates.add([receipt()]);
    await tester.pumpAndSettle();
    expect(app.user?.tier, 'pro');
    expect(find.textContaining('finish confirming'), findsOneWidget);
  });
}
