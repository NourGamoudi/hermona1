import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum RiskLevel { low, medium, high }
enum TrendDirection { increasing, stable, decreasing }

class PredictionResult extends Equatable {
  final String id;
  final double riskScore;
  final double riskJ3;
  final RiskLevel riskLevel;
  final TrendDirection trend;
  final Map<String, double> shapFactors;
  final int hygieneScore;
  final String? hygieneLevel;
  final Map<String, num>? hygieneBreakdown;
  final int cycleDay;
  final String cyclePhase;
  final DateTime predictedAt;

  const PredictionResult({
    required this.id,
    required this.riskScore,
    required this.riskJ3,
    required this.riskLevel,
    required this.trend,
    required this.shapFactors,
    required this.hygieneScore,
    this.hygieneLevel,
    this.hygieneBreakdown,
    required this.cycleDay,
    required this.cyclePhase,
    required this.predictedAt,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> j) {
    final scoreData = j['score'] as Map<String, dynamic>?;
    
    return PredictionResult(
      id: j['id'] as String,
      riskScore: (j['riskScore'] as num).toDouble(),
      riskJ3: (j['riskJ3'] ?? (j['riskScore'] as num).toDouble()).toDouble(),
      riskLevel: RiskLevel.values.firstWhere((e) => e.name == j['riskLevel'], orElse: () => RiskLevel.low),
      trend: TrendDirection.values.firstWhere((e) => e.name == (j['trend'] ?? 'stable'), orElse: () => TrendDirection.stable),
      shapFactors: j['shapFactors'] != null 
          ? (j['shapFactors'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))
          : {},
      // Root mapping for robustness
      hygieneScore: (j['hygieneScore'] as num?)?.toInt() ?? (scoreData?['value'] as num?)?.toInt() ?? 0,
      hygieneLevel: scoreData?['level'] as String?,
      hygieneBreakdown: scoreData?['breakdown'] != null 
          ? Map<String, num>.from(scoreData!['breakdown']) 
          : null,
      cycleDay: (j['cycleDay'] as num?)?.toInt() ?? 0,
      cyclePhase: j['cyclePhase'] ?? '',
      predictedAt: j['predictedAt'] is String ? DateTime.parse(j['predictedAt']) : (j['predictedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'riskScore': riskScore,
    'riskJ3': riskJ3,
    'riskLevel': riskLevel.name,
    'trend': trend.name,
    'shapFactors': shapFactors,
    'hygieneScore': hygieneScore,
    'hygieneLevel': hygieneLevel,
    'hygieneBreakdown': hygieneBreakdown,
    'cycleDay': cycleDay,
    'cyclePhase': cyclePhase,
    'predictedAt': Timestamp.fromDate(predictedAt),
  };

  @override
  List<Object?> get props => [
    id, riskScore, hygieneScore, predictedAt
  ];
}
