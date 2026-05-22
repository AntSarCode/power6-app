import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/api_constants.dart';

class PurchaseService {
  PurchaseService({InAppPurchase? inAppPurchase})
      : _iap = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  static bool get isAppleInAppPurchasePlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  static Set<String> get productIds =>
      ApiConstants.appStoreProductIds.values.toSet();

  static String productIdFor(String tier, String interval) {
    final key = '${tier.toLowerCase()}_${interval.toLowerCase()}';
    final productId = ApiConstants.appStoreProductIds[key];
    if (productId == null) {
      throw ArgumentError('No App Store product ID configured for $key');
    }
    return productId;
  }

  static String? tierForProductId(String productId) {
    for (final entry in ApiConstants.appStoreProductIds.entries) {
      if (entry.value == productId) {
        return entry.key.split('_').first;
      }
    }
    return null;
  }

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<ProductDetailsResponse> loadProducts() {
    return _iap.queryProductDetails(productIds);
  }

  Future<bool> buy(ProductDetails product) {
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  Future<void> completePurchase(PurchaseDetails purchase) {
    return _iap.completePurchase(purchase);
  }
}
