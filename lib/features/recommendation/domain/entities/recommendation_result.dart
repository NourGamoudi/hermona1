import 'package:equatable/equatable.dart';

class RoutineStep extends Equatable {
  final String step;
  final String product;
  final String instruction;
  final String icon;
  final List<String> productExamples;
  final String reason;

  const RoutineStep({
    required this.step,
    required this.product,
    required this.instruction,
    required this.icon,
    required this.productExamples,
    required this.reason,
  });

  factory RoutineStep.fromJson(Map<String, dynamic> j) => RoutineStep(
    step: j['step'] as String? ?? '1',
    product: j['product'] as String? ?? '',
    instruction: j['instruction'] as String? ?? '',
    icon: j['icon'] as String? ?? 'info',
    productExamples: List<String>.from(j['productExamples'] ?? []),
    reason: j['reason'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'step': step,
    'product': product,
    'instruction': instruction,
    'icon': icon,
    'productExamples': productExamples,
    'reason': reason,
  };

  @override
  List<Object?> get props => [step, product, productExamples, reason];
}

class RecommendationResult extends Equatable {
  final String id;
  final String detectionId;
  final List<RoutineStep> morningRoutine;
  final List<RoutineStep> eveningRoutine;
  final List<String> actives;
  final List<String> avoid;
  final List<String> lifestyle;
  final List<String> nutrition;
  final List<String> habits;
  final List<String> whyThis;
  final List<String> dietTips;
  final String strategy;
  final String alternativeStrategy;
  final int variationIndex;
  final double riskJ3;
  final double hygieneScore;
  final double severity;
  final String brands;
  final String duration;
  final String disclaimer;
  final String explanation;
  final DateTime createdAt;

  const RecommendationResult({
    required this.id,
    required this.detectionId,
    required this.morningRoutine,
    required this.eveningRoutine,
    required this.actives,
    required this.avoid,
    required this.lifestyle,
    required this.nutrition,
    required this.habits,
    required this.whyThis,
    required this.dietTips,
    required this.strategy,
    required this.alternativeStrategy,
    required this.variationIndex,
    required this.riskJ3,
    required this.hygieneScore,
    required this.severity,
    required this.brands,
    required this.duration,
    required this.disclaimer,
    required this.explanation,
    required this.createdAt,
  });

  factory RecommendationResult.fromJson(Map<String, dynamic> j) => RecommendationResult(
    id: j['id'] as String? ?? '',
    detectionId: j['detectionId'] as String? ?? '',
    morningRoutine: (j['routine_morning'] as List? ?? j['morningRoutine'] as List? ?? [])
        .map((i) => RoutineStep.fromJson(i as Map<String, dynamic>))
        .toList(),
    eveningRoutine: (j['routine_evening'] as List? ?? j['eveningRoutine'] as List? ?? [])
        .map((i) => RoutineStep.fromJson(i as Map<String, dynamic>))
        .toList(),
    actives: List<String>.from(j['actives'] ?? []),
    avoid: List<String>.from(j['avoid'] ?? []),
    lifestyle: List<String>.from(j['lifestyle'] ?? []),
    nutrition: List<String>.from(j['nutrition'] ?? []),
    habits: List<String>.from(j['habits'] ?? []),
    whyThis: List<String>.from(j['why_this'] ?? j['whyThis'] ?? []),
    dietTips: List<String>.from(j['diet_tips'] ?? j['dietTips'] ?? []),
    strategy: j['strategy'] as String? ?? '',
    alternativeStrategy: j['alternative_strategy'] as String? ?? j['alternativeStrategy'] as String? ?? '',
    variationIndex: (j['variation_index'] as num? ?? j['variationIndex'] as num? ?? 0).toInt(),
    riskJ3: (j['riskJ3'] as num? ?? 0.0).toDouble(),
    hygieneScore: (j['hygieneScore'] as num? ?? 70.0).toDouble(),
    severity: (j['severity'] as num? ?? 0.0).toDouble(),
    brands: j['brands'] as String? ?? 'CeraVe, La Roche-Posay',
    duration: j['duration'] as String? ?? '5 min',
    disclaimer: j['disclaimer'] as String? ?? 'Consultez un dermatologue.',
    explanation: j['explanation'] as String? ?? '',
    createdAt: j['createdAt'] != null
        ? DateTime.parse(j['createdAt'] as String)
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'detectionId': detectionId,
    'routine_morning': morningRoutine.map((i) => i.toJson()).toList(),
    'routine_evening': eveningRoutine.map((i) => i.toJson()).toList(),
    'actives': actives,
    'avoid': avoid,
    'lifestyle': lifestyle,
    'nutrition': nutrition,
    'habits': habits,
    'why_this': whyThis,
    'diet_tips': dietTips,
    'strategy': strategy,
    'alternative_strategy': alternativeStrategy,
    'variation_index': variationIndex,
    'riskJ3': riskJ3,
    'hygieneScore': hygieneScore,
    'severity': severity,
    'brands': brands,
    'duration': duration,
    'disclaimer': disclaimer,
    'explanation': explanation,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, strategy, alternativeStrategy, variationIndex, riskJ3];
}
