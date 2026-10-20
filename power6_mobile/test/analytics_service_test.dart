import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:power6_mobile/services/analytics_service.dart';
import 'package:power6_mobile/services/api_service.dart';

class ClosingClient extends MockClient {
  ClosingClient(super.handler);
  bool closed = false;

  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  test('does not send anonymous events or requests after disposal', () async {
    var calls = 0;
    final client = ClosingClient((request) async {
      calls++;
      return http.Response('{}', 201);
    });
    final analytics =
        AnalyticsService(api: ApiService('https://example.com', client));
    await analytics.track('dashboard_viewed', token: null);
    await analytics.track('dashboard_viewed', token: '');
    analytics.dispose();
    analytics.dispose();
    await analytics.track('dashboard_viewed', token: 'token');
    expect(calls, 0);
    expect(client.closed, isTrue);
  });

  test('screen disposal lets in-flight telemetry finish before closing',
      () async {
    final release = Completer<http.Response>();
    final started = Completer<void>();
    final client = ClosingClient((request) {
      expect(request.headers['Authorization'], 'Bearer token');
      expect(jsonDecode(request.body)['name'], 'onboarding_completed');
      started.complete();
      return release.future;
    });
    final analytics =
        AnalyticsService(api: ApiService('https://example.com', client));
    final sent = analytics.track('onboarding_completed', token: 'token');
    await started.future;
    analytics.dispose();
    expect(client.closed, isFalse);
    release.complete(http.Response('{}', 201));
    await sent;
    expect(client.closed, isTrue);
  });

  test('telemetry failures do not escape into app flows', () async {
    final client =
        ClosingClient((request) async => throw StateError('offline'));
    final analytics =
        AnalyticsService(api: ApiService('https://example.com', client));
    await expectLater(
        analytics.track('dashboard_viewed', token: 'token'), completes);
    analytics.dispose();
    expect(client.closed, isTrue);
  });
}
