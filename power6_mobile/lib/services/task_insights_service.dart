import '../config/api_constants.dart';
import 'api_service.dart';

class TaskInsightsService {
  final ApiService _api;

  TaskInsightsService({ApiService? api})
      : _api = api ?? ApiService(ApiConstants.baseUrl, null);

  Future<ApiResponse> fetchAnalytics({
    required String token,
    DateTime? from,
    DateTime? to,
  }) {
    return _api.get(
      ApiConstants.taskAnalytics,
      token: token,
      query: _dateRange(from: from, to: to),
    );
  }

  Future<ApiResponse> exportCsv({
    required String token,
    DateTime? from,
    DateTime? to,
  }) {
    return _api.get(
      ApiConstants.taskExportCsv,
      token: token,
      query: _dateRange(from: from, to: to),
    );
  }

  Map<String, dynamic> _dateRange({DateTime? from, DateTime? to}) {
    String ymd(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return <String, dynamic>{
      if (from != null) 'from_date': ymd(from.toUtc()),
      if (to != null) 'to_date': ymd(to.toUtc()),
    };
  }

  void dispose() => _api.dispose();
}
