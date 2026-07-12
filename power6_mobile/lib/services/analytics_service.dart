import 'dart:async';

import '../config/api_constants.dart';
import 'api_service.dart';

class AnalyticsService {
  final ApiService _api;

  AnalyticsService({ApiService? api})
      : _api = api ?? ApiService(ApiConstants.baseUrl, null);

  void track(
    String name, {
    required String? token,
    Map<String, dynamic> properties = const <String, dynamic>{},
  }) async {
    if (token == null || token.isEmpty) return;
    unawaited(
      _api.post(
        ApiConstants.events,
        token: token,
        body: <String, dynamic>{
          'name': name,
          'source': 'mobile',
          'properties': properties,
        },
      ),
    );
  }

  void dispose() => _api.dispose();
}
