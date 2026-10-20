import '../config/api_constants.dart';
import 'api_service.dart';

class AnalyticsService {
  final ApiService _api;
  bool _disposed = false;
  int _pending = 0;

  AnalyticsService({ApiService? api})
      : _api = api ?? ApiService(ApiConstants.baseUrl, null);

  Future<void> track(
    String name, {
    required String? token,
    Map<String, dynamic> properties = const <String, dynamic>{},
  }) async {
    if (_disposed || token == null || token.isEmpty) return;
    _pending++;
    try {
      await _api.post(
        ApiConstants.events,
        token: token,
        body: <String, dynamic>{
          'name': name,
          'source': 'mobile',
          'properties': properties,
        },
      );
    } catch (_) {
      // Optional telemetry must never interrupt planning or navigation.
    } finally {
      _pending--;
      if (_disposed && _pending == 0) _api.dispose();
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    // Let bounded in-flight requests finish when a screen is replaced.
    if (_pending == 0) _api.dispose();
  }
}
