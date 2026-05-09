import 'package:equatable/equatable.dart';

enum SeverityLevel { normal, moderate, severe, verySevere }

class AcneClassification extends Equatable {
  final String type;          // Blackhead | Whitehead | Papule | Pustule | Nodule
  final double percentage;    // 0.0 → 1.0
  final String cause;         // explication de la cause
  final String description;   // description du type

  const AcneClassification({
    required this.type,
    required this.percentage,
    required this.cause,
    required this.description,
  });

  factory AcneClassification.fromJson(Map<String, dynamic> j) => AcneClassification(
    type       : j['type']        as String,
    percentage : (j['percentage'] as num).toDouble(),
    cause      : j['cause']       as String,
    description: j['description'] as String,
  );

  Map<String, dynamic> toJson() => {
    'type': type, 'percentage': percentage,
    'cause': cause, 'description': description,
  };

  @override
  List<Object?> get props => [type, percentage];
}

class DetectionResult extends Equatable {
  final String id;
  final double severityScore;               // 0.0 → 100.0
  final SeverityLevel severityLevel;
  final List<AcneClassification> classifications;
  final DateTime analyzedAt;
  final List<String> imageUrls;
  final Map<String, Map<String, int>>? zoneCounts;
  final Map<String, double>? zoneRisks; // Score de risque par zone

  const DetectionResult({
    required this.id,
    required this.severityScore,
    required this.severityLevel,
    required this.classifications,
    required this.analyzedAt,
    required this.imageUrls,
    this.zoneCounts,
    this.zoneRisks,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> j) => DetectionResult(
    id            : j['id'] as String,
    severityScore : (j['severityScore'] as num).toDouble(),
    severityLevel : SeverityLevel.values.firstWhere((e) => e.name == j['severityLevel']),
    classifications: (j['classifications'] as List).map((c) => AcneClassification.fromJson(c as Map<String, dynamic>)).toList(),
    analyzedAt    : j['analyzedAt'] is String 
        ? DateTime.parse(j['analyzedAt'] as String)
        : (j['analyzedAt'] as dynamic).toDate(),
    imageUrls     : List<String>.from(j['imageUrls'] ?? []),
    zoneCounts    : j['zoneCounts'] != null 
        ? (j['zoneCounts'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, (v as Map<String, dynamic>).cast<String, int>()),
          )
        : null,
    zoneRisks     : j['zoneRisks'] != null
        ? (j['zoneRisks'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          )
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'severityScore': severityScore,
    'severityLevel': severityLevel.name,
    'classifications': classifications.map((c) => c.toJson()).toList(),
    'analyzedAt': analyzedAt.toIso8601String(),
    'imageUrls': imageUrls,
    'zoneCounts': zoneCounts,
    'zoneRisks': zoneRisks,
  };

  @override
  List<Object?> get props => [id, severityScore, imageUrls, zoneCounts, zoneRisks];
}
