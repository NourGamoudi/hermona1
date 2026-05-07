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

  void loadData() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      emit(TrendsError("Non connecté"));
      return;
    }

    emit(TrendsLoading());

    // In a real app, we would use a repository and combine streams or wait for futures.
    // For simplicity, we'll fetch both collections.
    
    FirebaseFirestore.instance
        .collection('detections')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((detSnap) {
          FirebaseFirestore.instance
              .collection('predictions')
              .where('userId', isEqualTo: uid)
              .snapshots()
              .listen((predSnap) {
                if (!isClosed) {
                  emit(TrendsLoaded(
                    detections: detSnap.docs,
                    predictions: predSnap.docs,
                  ));
                }
              });
        }, onError: (e) {
          if (!isClosed) emit(TrendsError(e.toString()));
        });
  }
}
