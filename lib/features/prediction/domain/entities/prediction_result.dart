import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN – Prediction Entities
// ─────────────────────────────────────────────────────────────────────────────
enum RiskLevel { low, medium, high }
enum TrendDirection { increasing, stable, decreasing }

class PredictionResult extends Equatable {
  final String id;
  final double riskScore;           // 0.0 → 1.0
  final double riskJ3;              // Prediction for J+3
  final RiskLevel riskLevel;
  final TrendDirection trend;
  final Map<String, double> shapFactors; // Top 3 factors with their SHAP values
  final int hygieneScore;
  final int cycleDay;
  final String cyclePhase;
  final List<String> routine;
  final List<String> toAvoid;
  final List<String> lifestyle;
  final DateTime predictedAt;

  const PredictionResult({
    required this.id,
    required this.riskScore,
    required this.riskJ3,
    required this.riskLevel,
    required this.trend,
    required this.shapFactors,
    required this.hygieneScore,
    required this.cycleDay,
    required this.cyclePhase,
    required this.routine,
    required this.toAvoid,
    required this.lifestyle,
    required this.predictedAt,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> j) => PredictionResult(
    id            : j['id']       as String,
    riskScore     : (j['riskScore'] as num).toDouble(),
    riskJ3        : (j['riskJ3'] ?? (j['riskScore'] as num).toDouble()).toDouble(),
    riskLevel     : RiskLevel.values.firstWhere((e) => e.name == j['riskLevel'], orElse: () => RiskLevel.low),
    trend         : TrendDirection.values.firstWhere((e) => e.name == (j['trend'] ?? 'stable'), orElse: () => TrendDirection.stable),
    shapFactors   : j['shapFactors'] != null ? Map<String, double>.from(j['shapFactors']) : {},
    hygieneScore  : j['hygieneScore'] ?? 0,
    cycleDay      : j['cycleDay'] ?? 0,
    cyclePhase    : j['cyclePhase'] ?? '',
    routine       : List<String>.from(j['routine'] ?? []),
    toAvoid       : List<String>.from(j['toAvoid'] ?? []),
    lifestyle     : List<String>.from(j['lifestyle'] ?? []),
    predictedAt   : j['predictedAt'] is String ? DateTime.parse(j['predictedAt']) : (j['predictedAt'] as Timestamp).toDate(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'riskScore': riskScore,
    'riskJ3': riskJ3,
    'riskLevel': riskLevel.name,
    'trend': trend.name,
    'shapFactors': shapFactors,
    'hygieneScore': hygieneScore,
    'cycleDay': cycleDay,
    'cyclePhase': cyclePhase,
    'routine': routine,
    'toAvoid': toAvoid,
    'lifestyle': lifestyle,
    'predictedAt': Timestamp.fromDate(predictedAt),
  };

  @override
  List<Object?> get props => [id, riskScore];
}
