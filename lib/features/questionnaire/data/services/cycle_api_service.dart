import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:acneia/core/constants/app_constants.dart';

class CycleStatus {
  final int day;
  final String phase;
  final int ovulationDay;
  final int cycleLength;
  final int menstruationDuration;

  CycleStatus({
    required this.day,
    required this.phase,
    required this.ovulationDay,
    required this.cycleLength,
    required this.menstruationDuration,
  });

  factory CycleStatus.fromJson(Map<String, dynamic> json) {
    return CycleStatus(
      day: json['cycleDay'] ?? 1,
      phase: json['cyclePhase'] ?? 'unknown',
      ovulationDay: json['ovulationDay'] ?? 14,
      cycleLength: json['cycleLength'] ?? 28,
      menstruationDuration: json['menstruationDuration'] ?? 5,
    );
  }
}

class CycleApiService {
  final Dio _dio;

  CycleApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          headers: {'X-API-Key': AppConstants.apiKey},
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  Future<CycleStatus> getCycleStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    final response = await _dio.get('/cycle-status/$uid');
    if (response.data == null || response.data['error'] != null) {
      throw Exception(response.data?['error'] ?? 'Failed to get cycle status');
    }

    return CycleStatus.fromJson(response.data);
  }
}
