import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:acneia/features/forum/data/services/forum_service.dart';

abstract class ForumState {}

class ForumInitial extends ForumState {}

class ForumLoading extends ForumState {}

class ForumLoaded extends ForumState {
  final List<QueryDocumentSnapshot> posts;
  ForumLoaded(this.posts);
}

class ForumError extends ForumState {
  final String message;
  ForumError(this.message);
}

class ForumCubit extends Cubit<ForumState> {
  final ForumService _service;
  
  ForumCubit(this._service) : super(ForumInitial());

  void loadPosts({String? category, String sort = 'date'}) {
    emit(ForumLoading());
    _service.getPosts(category: category, sort: sort).listen(
      (snap) {
        if (!isClosed) emit(ForumLoaded(snap.docs));
      },
      onError: (e) {
        if (!isClosed) emit(ForumError(e.toString()));
      },
    );
  }

  Future<void> createPost(String title, String content, String category) async {
    try {
      await _service.createPost(title: title, content: content, category: category);
    } catch (e) {
      emit(ForumError(e.toString()));
    }
  }

  Future<void> toggleLike(String targetId, String targetCollection, String counterField) async {
    try {
      await _service.toggleLike(targetId: targetId, targetCollection: targetCollection, counterField: counterField);
    } catch (e) {
      emit(ForumError(e.toString()));
    }
  }
}
