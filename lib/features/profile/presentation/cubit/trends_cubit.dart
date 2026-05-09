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
      // Field: severityScore, Date: analyzedAt
      // We fetch latest 20 for chronological evolution preview.
      final detSnap = await FirebaseFirestore.instance
          .collection('detections')
          .where('userId', isEqualTo: uid)
          .orderBy('analyzedAt', descending: true)
          .limit(20)
          .get(const GetOptions(source: Source.serverAndCache));

      // 2. RISK SOURCE: Daily questionnaire predictions (colPredictions)
      // Field: riskScore, Date: predictedAt
      final predSnap = await FirebaseFirestore.instance
          .collection('predictions')
          .where('userId', isEqualTo: uid)
          .orderBy('predictedAt', descending: true)
          .limit(20)
          .get(const GetOptions(source: Source.serverAndCache));

      // DATA INTEGRITY: Sort chronologically (ascending) for the chart
      final detections = detSnap.docs.toList();
      detections.sort((a, b) => (a['analyzedAt'] as String).compareTo(b['analyzedAt'] as String));

      final predictions = predSnap.docs.toList();
      predictions.sort((a, b) => (a['predictedAt'] as String).compareTo(b['predictedAt'] as String));

      if (!isClosed) {
        emit(TrendsLoaded(
          detections: detections,
          predictions: predictions,
        ));
      }
    } catch (e) {
      if (!isClosed) emit(TrendsError("Erreur historique: $e"));
    }
  }
}
