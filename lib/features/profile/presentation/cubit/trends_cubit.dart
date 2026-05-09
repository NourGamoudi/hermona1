import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class TrendsState {}

class TrendsInitial extends TrendsState {}

class TrendsLoading extends TrendsState {}

class TrendsLoaded extends TrendsState {
  final List<QueryDocumentSnapshot> detections;
  final List<QueryDocumentSnapshot> predictions;
  TrendsLoaded({required this.detections, required this.predictions});
}

class TrendsError extends TrendsState {
  final String message;
  TrendsError(this.message);
}

class TrendsCubit extends Cubit<TrendsState> {
  TrendsCubit() : super(TrendsInitial());

  Future<void> loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      emit(TrendsError("Non connecté"));
      return;
    }

    emit(TrendsLoading());

    try {
      // 1. SEVERITY SOURCE: Weekly analysis history (colDetections)
      // Query Rule: Recent history first, limit to 20 to prevent memory pressure.
      final detSnap = await FirebaseFirestore.instance
          .collection('detections')
          .where('userId', isEqualTo: uid)
          .orderBy('analyzedAt', descending: true)
          .limit(20)
          .get(const GetOptions(source: Source.serverAndCache));

      // 2. RISK SOURCE: Daily questionnaire predictions (colPredictions)
      // Query Rule: Recent history first, limit to 20.
      final predSnap = await FirebaseFirestore.instance
          .collection('predictions')
          .where('userId', isEqualTo: uid)
          .orderBy('predictedAt', descending: true)
          .limit(20)
          .get(const GetOptions(source: Source.serverAndCache));

      // DATA INTEGRITY: Strict historical mapping. Skip invalid docs.
      final detections = detSnap.docs.where((d) => d.data()['analyzedAt'] != null).toList()
        ..sort((a, b) => (a['analyzedAt'] as String).compareTo(b['analyzedAt'] as String));

      final predictions = predSnap.docs.where((d) => d.data()['predictedAt'] != null).toList()
        ..sort((a, b) => (a['predictedAt'] as String).compareTo(b['predictedAt'] as String));

      if (!isClosed) {
        emit(TrendsLoaded(
          detections: detections,
          predictions: predictions,
        ));
      }
    } catch (e) {
      debugPrint("Trends Load Error: $e");
      if (!isClosed) emit(TrendsError("Erreur d'historique réel: $e"));
    }
  }
}
