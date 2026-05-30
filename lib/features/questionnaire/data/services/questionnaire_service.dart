import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:acneia/features/questionnaire/domain/entities/user_profile.dart';

import 'package:acneia/features/questionnaire/domain/entities/daily_survey.dart';

import 'package:acneia/features/questionnaire/domain/entities/weekly_survey.dart';

import 'package:intl/intl.dart';

import 'package:acneia/core/constants/app_constants.dart';
import 'package:acneia/features/forum/data/services/forum_service.dart';

class QuestionnaireService {

  final _db = FirebaseFirestore.instance;



  // Profil utilisateur

  Future<UserProfile?> fetchUserProfile(String userId) async {

    final doc = await _db.collection('users').doc(userId).get();

    if (!doc.exists) return null;

    return UserProfile.fromJson(doc.data()!, doc.id);

  }



  Future<void> saveUserProfile(UserProfile profile) async {

    await _db.collection(AppConstants.colUsers).doc(profile.id).set(profile.toJson());
    if (profile.pseudonym != null && profile.pseudonym!.isNotEmpty) {
      await _db.collection(AppConstants.colPublicProfiles).doc(profile.id).set({
        'uid': profile.id,
        'pseudonym': profile.pseudonym,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      ForumService.invalidateProfile(profile.id);
    }

  }



  // Questionnaire quotidien

  Future<DailySurvey?> fetchDailySurvey(String userId, DateTime date) async {

    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    final id = '${userId}_$formattedDate';

    final doc = await _db.collection('daily_surveys').doc(id).get();

    if (!doc.exists) return null;

    return DailySurvey.fromJson(doc.data()!, doc.id);

  }



  Future<void> saveDailySurvey(DailySurvey survey) async {

    await _db.collection('daily_surveys').doc(survey.id).set(survey.toJson());

  }



  // Questionnaire hebdomadaire

  Future<WeeklySurvey?> fetchWeeklySurvey(String userId, int weekNumber, int year) async {

    final id = '${userId}_${weekNumber}_$year';

    final doc = await _db.collection('weekly_surveys').doc(id).get();

    if (!doc.exists) return null;

    return WeeklySurvey.fromJson(doc.data()!, doc.id);

  }



  Future<void> saveWeeklySurvey(WeeklySurvey survey) async {

    await _db.collection('weekly_surveys').doc(survey.id).set(survey.toJson(), SetOptions(merge: true));

  }

}



