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
      // 1. SEVERITY SOURCE: Weekly analysis (detections)
      final detSnap = await FirebaseFirestore.instance
          .collection('detections')
          .where('userId', isEqualTo: uid)
          .orderBy('analyzedAt', descending: true)
          .limit(15)
          .get(const GetOptions(source: Source.server));

      // 2. RISK SOURCE: Daily questionnaires (predictions)
      final predSnap = await FirebaseFirestore.instance
          .collection('predictions')
          .where('userId', isEqualTo: uid)
          .orderBy('predictedAt', descending: true)
          .limit(15)
          .get(const GetOptions(source: Source.server));

      // DATA INTEGRITY: Strict historical mapping with robust date sorting
      final detections = detSnap.docs.where((d) => d.data()['analyzedAt'] != null).toList()
        ..sort((a, b) {
          final da = a['analyzedAt'];
          final db = b['analyzedAt'];
          final DateTime dtA = (da is Timestamp) ? da.toDate() : DateTime.parse(da.toString());
          final DateTime dtB = (db is Timestamp) ? db.toDate() : DateTime.parse(db.toString());
          return dtA.compareTo(dtB);
        });

      final predictions = predSnap.docs.where((d) => d.data()['predictedAt'] != null).toList()
        ..sort((a, b) {
          final da = a['predictedAt'];
          final db = b['predictedAt'];
          final DateTime dtA = (da is Timestamp) ? da.toDate() : DateTime.parse(da.toString());
          final DateTime dtB = (db is Timestamp) ? db.toDate() : DateTime.parse(db.toString());
          return dtA.compareTo(dtB);
        });

      if (!isClosed) {
        emit(TrendsLoaded(
          detections: detections,
          predictions: predictions,
        ));
      }
    } catch (e) {
      debugPrint("Trends Load Error: $e");
      if (!isClosed) emit(TrendsError("Échec de synchronisation historique: $e"));
    }
  }
}
