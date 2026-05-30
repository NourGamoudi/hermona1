import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import 'package:acneia/core/constants/app_constants.dart';

class ForumService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  static final Map<String, Future<DocumentSnapshot>> _profileCache = {};

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  static void invalidateProfile(String userId) {
    _profileCache.remove(userId);
  }

  Stream<QuerySnapshot> getPosts({
    String? category,
    String sort = 'date',
    int limit = 25,
  }) {
    Query query = _db
        .collection(AppConstants.colForumPosts)
        .where('visible', isEqualTo: true);

    if (category != null && category.isNotEmpty && category != 'ALL') {
      query = query.where('category', isEqualTo: category);
    }

    query = sort == 'popular'
        ? query.orderBy('likesCount', descending: true)
        : query.orderBy('createdAt', descending: true);

    return query.limit(limit).snapshots();
  }

  Future<DocumentSnapshot> getAuthorProfile(String authorId) {
    return _profileCache.putIfAbsent(
      authorId,
      () => _db.collection(AppConstants.colPublicProfiles).doc(authorId).get(),
    );
  }

  Future<String> createPost({
    required String title,
    required String content,
    required String category,
  }) async {
    final id = _uuid.v4();

    await _db.collection(AppConstants.colForumPosts).doc(id).set({
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'authorId': _uid,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': 0,
      'repliesCount': 0,
      'reportsCount': 0,
      'visible': true,
    });

    return id;
  }

  Future<void> deletePost(String postId) async {
    final doc = await _db.collection(AppConstants.colForumPosts).doc(postId).get();

    if (doc.data()?['authorId'] == _uid) {
      await _db.collection(AppConstants.colForumPosts).doc(postId).update({
        'visible': false,
      });
    }
  }

  Future<void> toggleLike({
    required String targetId,
    required String targetCollection,
    required String counterField,
  }) async {
    final likeRef = _db.collection(AppConstants.colLikes).doc('${_uid}_$targetId');
    final likeDoc = await likeRef.get();
    final targetRef = _db.collection(targetCollection).doc(targetId);

    if (likeDoc.exists) {
      await likeRef.delete();
      await targetRef.update({counterField: FieldValue.increment(-1)});
    } else {
      await likeRef.set({
        'userId': _uid,
        'targetId': targetId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await targetRef.update({counterField: FieldValue.increment(1)});
    }
  }

  Future<bool> isLiked(String targetId) async {
    final doc = await _db.collection(AppConstants.colLikes).doc('${_uid}_$targetId').get();
    return doc.exists;
  }

  Stream<QuerySnapshot> getReplies(String postId) {
    return _db
        .collection(AppConstants.colForumReplies)
        .where('postId', isEqualTo: postId)
        .where('visible', isEqualTo: true)
        .orderBy('createdAt')
        .snapshots();
  }

  Future<void> addReply({
    required String postId,
    required String content,
    String? parentReplyId,
  }) async {
    final id = _uuid.v4();

    await _db.collection(AppConstants.colForumReplies).doc(id).set({
      'id': id,
      'postId': postId,
      'content': content,
      'authorId': _uid,
      'parentReplyId': parentReplyId,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': 0,
      'reportsCount': 0,
      'visible': true,
    });

    await _db.collection(AppConstants.colForumPosts).doc(postId).update({
      'repliesCount': FieldValue.increment(1),
    });
  }

  Future<void> deleteReply(String replyId, String postId) async {
    final doc = await _db.collection(AppConstants.colForumReplies).doc(replyId).get();

    if (doc.data()?['authorId'] == _uid) {
      await _db.collection(AppConstants.colForumReplies).doc(replyId).update({
        'visible': false,
      });
      await _db.collection(AppConstants.colForumPosts).doc(postId).update({
        'repliesCount': FieldValue.increment(-1),
      });
    }
  }

  Future<void> reportContent({
    required String targetId,
    required String targetType,
    required String reason,
  }) async {
    final reportId = _uuid.v4();
    final collection = targetType == 'post'
        ? AppConstants.colForumPosts
        : AppConstants.colForumReplies;

    await _db.collection(AppConstants.colReports).doc(reportId).set({
      'id': reportId,
      'targetId': targetId,
      'targetType': targetType,
      'reporterId': _uid,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.runTransaction((transaction) async {
      final ref = _db.collection(collection).doc(targetId);
      final snap = await transaction.get(ref);
      final count = ((snap.data()?['reportsCount'] as num?)?.toInt() ?? 0) + 1;

      transaction.update(ref, {
        'reportsCount': count,
        if (count >= 3) 'visible': false,
      });
    });
  }
}
