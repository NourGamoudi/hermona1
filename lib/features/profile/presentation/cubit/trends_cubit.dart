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
      // MEMORY FIX: Use one-time .get() with .limit(20) instead of unbounded
      // real-time .snapshots(). This prevents loading all historical documents
      // (each potentially containing 500KB+ of base64 image data) into the
      // Android SQLite local cache, which caused CursorWindow NO_MEMORY errors.
      final detFuture = FirebaseFirestore.instance
          .collection('detections')
          .where('userId', isEqualTo: uid)
          .orderBy('analyzedAt', descending: true)
          .limit(20)
          .get(const GetOptions(source: Source.serverAndCache));

      final predFuture = FirebaseFirestore.instance
          .collection('predictions')
          .where('userId', isEqualTo: uid)
          .orderBy('predictedAt', descending: true)
          .limit(20)
          .get(const GetOptions(source: Source.serverAndCache));

      final results = await Future.wait([detFuture, predFuture]);

      if (!isClosed) {
        emit(TrendsLoaded(
          detections: results[0].docs,
          predictions: results[1].docs,
        ));
      }
    } catch (e) {
      if (!isClosed) emit(TrendsError(e.toString()));
    }
  }
}
