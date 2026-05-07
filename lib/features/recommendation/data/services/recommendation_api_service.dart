import 'package:cloud_firestore/cloud_firestore.dart';

// import 'package:dio/dio.dart';



import '../../domain/entities/recommendation_result.dart';

import '../../domain/repositories/recommendation_repository.dart';

import '../../../detection/domain/entities/detection_result.dart';

import '../../../../core/constants/app_constants.dart';

// import '../../../../core/errors/app_exception.dart';



// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// DATA ”“ Implémentation du RecommendationRepository

//

// âœ… MOCK ACTIF  ”“ simulation locale

// 🧴”Œ API RÉELLE  ”“ commentée, endpoint : POST /recommend

//

// Pour passer à l'API réelle :

//   1. Décommentez les imports Dio et ApiException

//   2. Décommentez le bloc [API RÉELLE] dans getRecommendations()

//   3. Supprimez le bloc [MOCK ”“ À SUPPRIMER]

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class RecommendationApiService implements RecommendationRepository {



  // final Dio _dio;

  // RecommendationApiService()

  //     : _dio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));



  final FirebaseFirestore _db = FirebaseFirestore.instance;



  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override

  Future<RecommendationResult> getRecommendations({

    required DetectionResult detection,

    required String userId,

  }) async {



    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

    // [API RÉELLE] ”“ POST /recommend

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

    // try {

    //   final response = await _dio.post<Map<String, dynamic>>(

    //     '/recommend',

    //     data: {

    //       'detection'  : detection.toJson(),

    //       'userId'     : userId,

    //     },

    //   );

    //   return RecommendationResult.fromJson(response.data!);

    // } on DioException catch (e) {

    //   throw ApiException(

    //     e.response?.data?['detail'] ?? 'Erreur recommandation',

    //     statusCode: e.response?.statusCode,

    //   );

    // }

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•



    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

    // [MOCK ”“ À SUPPRIMER]

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

    await Future.delayed(const Duration(seconds: 2));



    final isSevere   = detection.severityLevel == SeverityLevel.severe;

    final isModerate = detection.severityLevel == SeverityLevel.moderate;



    return RecommendationResult(

      id            : 'rec_${DateTime.now().millisecondsSinceEpoch}',

      detectionId   : detection.id,

      createdAt     : DateTime.now(),

      duration      : isSevere ? '12 semaines' : isModerate ? '8 semaines' : '4 semaines',

      morningRoutine: [

        const RoutineStep(step: '1', product: 'Nettoyant doux pH neutre',       instruction: 'Nettoyez votre visage 30 s, rincez à l\'eau tiède', icon: '🧴§´'),

        const RoutineStep(step: '2', product: 'Tonique sans alcool',            instruction: 'Appliquez sur coton, tapotez délicatement',          icon: '🧴’§'),

        if (isModerate || isSevere)

          const RoutineStep(step: '3', product: 'Sérum Niacinamide 10%',       instruction: '3-4 gouttes, massez en mouvements circulaires',       icon: '✨'),

        RoutineStep(step: isSevere ? '4' : '3', product: 'Hydratant non-comédogène', instruction: 'Appliquez sur peau encore légèrement humide',   icon: '🌍¿'),

        RoutineStep(step: isSevere ? '5' : '4', product: 'SPF 30+ minéral',         instruction: 'Indispensable même les jours nuageux',           icon: 'â˜€ï¸'),

      ],

      eveningRoutine: [

        const RoutineStep(step: '1', product: 'Huile démaquillante',            instruction: 'Massez sur visage sec, émulsionnez avec un peu d\'eau', icon: '🌙'),

        const RoutineStep(step: '2', product: 'Nettoyant Acide Salicylique 2%', instruction: '60 s de massage, insistez sur zones T',                icon: '🧴§¼'),

        const RoutineStep(step: '3', product: 'Tonique AHA/BHA',               instruction: 'Exfoliation chimique douce 3Ï— / semaine max',           icon: 'âš—ï¸'),

        if (isSevere)

          const RoutineStep(step: '4', product: 'Rétinoïde 0.025%',            instruction: 'Fine couche, 2-3Ï— / semaine, augmenter graduellement', icon: '🧴’Š'),

        RoutineStep(step: isSevere ? '5' : '4', product: 'Crème barrière nuit', instruction: 'Appliquez généreusement pour réparer la barrière cutanée', icon: '🌍›'),

      ],

      dietTips: [

        '🥗 Privilégiez les aliments à faible indice glycémique (légumineuses, légumes)',

        '🧴« Antioxydants : myrtilles, épinards, noix du Brésil',

        '🧴’¦ 2 L d\'eau minimum par jour',

        '🧴Ÿ Oméga-3 : saumon, sardines, graines de chia',

        'âŒ Réduire sucres raffinés, sodas et ultra-transformés',

        if (isSevere) '🧴¥› Tester l\'élimination des produits laitiers 4 semaines',

        '🧴µ Thé vert : EGCG anti-inflammatoire puissant',

        '🌍¾ Zinc : huîtres, graines de courge, légumineuses',

      ],

    );

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  }



  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override

  Future<void> saveResult(RecommendationResult result, String userId) async {

    await _db

        .collection(AppConstants.colRecommendations)

        .doc(result.id)

        .set({...result.toJson(), 'userId': userId});

  }



  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override

  Future<RecommendationResult?> getForDetection(String detectionId) async {

    final snap = await _db

        .collection(AppConstants.colRecommendations)

        .where('detectionId', isEqualTo: detectionId)

        .limit(1)

        .get();

    if (snap.docs.isEmpty) return null;

    return RecommendationResult.fromJson(snap.docs.first.data());

  }

}



