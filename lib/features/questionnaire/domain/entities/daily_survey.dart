import 'package:cloud_firestore/cloud_firestore.dart';



class DailySurvey {

  final String id;

  final String userId;

  final DateTime date;

  final int stress;

  final double sleepDuration;

  final int sleepQuality;

  final int hydration;

  final List<String> food;

  final List<String> symptoms;

  final int cycleDay;

  final String cyclePhase;

  final int lifestyleScore;



  DailySurvey({

    required this.id,

    required this.userId,

    required this.date,

    required this.stress,

    required this.sleepDuration,

    required this.sleepQuality,

    required this.hydration,

    required this.food,

    required this.symptoms,

    required this.cycleDay,

    required this.cyclePhase,

    required this.lifestyleScore,

  });



  factory DailySurvey.fromJson(Map<String, dynamic> json, String id) {

    return DailySurvey(

      id: id,

      userId: json['userId'] ?? '',

      date: json['date'] is String 
          ? DateTime.parse(json['date']) 
          : (json['date'] as dynamic).toDate(),

      stress: json['stress'] ?? json['stress_level'] ?? 0,

      sleepDuration: (json['sleepDuration'] ?? json['sleep_hours'] ?? 0).toDouble(),

      sleepQuality: json['sleepQuality'] ?? json['sleep_quality'] ?? 0,

      hydration: json['hydration'] ?? json['water_glasses'] ?? 0,

      food: List<String>.from(json['food'] ?? json['diet_tags'] ?? []),

      symptoms: List<String>.from(json['symptoms'] ?? []),

      cycleDay: json['cycleDay'] ?? 0,

      cyclePhase: json['cyclePhase'] ?? '',

      lifestyleScore: json['lifestyleScore'] ?? 0,

    );

  }



  Map<String, dynamic> toJson() {

    return {

      'userId': userId,

      'date': Timestamp.fromDate(date),

      'stress': stress,
      'stress_level': stress,

      'sleepDuration': sleepDuration,
      'sleep_hours': sleepDuration,

      'sleepQuality': sleepQuality,
      'sleep_quality': sleepQuality,

      'hydration': hydration,
      'water_glasses': hydration,

      'food': food,
      'diet_tags': food,

      'symptoms': symptoms,

      'cycleDay': cycleDay,

      'cyclePhase': cyclePhase,

      'lifestyleScore': lifestyleScore,

    };

  }

}



