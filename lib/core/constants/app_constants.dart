import 'package:flutter/foundation.dart' show kReleaseMode;

class AppConstants {
  // ——————————————————————————————————————————————————————————————————————————————————————
  static const String apiBaseUrl = kReleaseMode 
      ? 'https://hermona-api.onrender.com' // PROD
      : 'http://10.179.75.131:8000'; // DEV (Auto-detected IP)
  static const String apiKey     = 'hermona_secret_2026';



  // â”€â”€ Appwrite â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static const String appwriteEndpoint  = 'https://cloud.appwrite.io/v1';

  static const String appwriteProjectId = 'YOUR_APPWRITE_PROJECT_ID';

  static const String appwriteBucketId  = 'YOUR_BUCKET_ID';



  // â”€â”€ Firestore Collections â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static const String colUsers           = 'users';

  static const String colDetections      = 'detections';

  static const String colRecommendations = 'recommendations';

  static const String colPredictions     = 'predictions';

  static const String colChatHistory     = 'chat_history';

  static const String colForumPosts      = 'forum_posts';

  static const String colForumReplies    = 'forum_replies';

  static const String colConversations   = 'conversations';

  static const String colMessages        = 'messages';

  static const String colLikes           = 'likes';

  static const String colReports         = 'reports';
  static const String colNotifications   = 'notifications';
  static const String colDailySurveys   = 'daily_surveys';
  static const String colPublicProfiles  = 'public_profiles';



  // ——————————————————————————————————————————————————————————————————————————————————————

  static const String keyThemeMode     = 'theme_mode';

  static const String keyPrimaryColor  = 'primary_color';

  static const String keyWelcomeShown  = 'welcome_shown';



  // â”€â”€ Forum Categories â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static const List<String> forumCategories = [

    'Général', 'Routine beauté', 'Alimentation',

    'Hormones', 'Traitements', 'Témoignages', 'Questions',

  ];



  // â”€â”€ Photo tips â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static const String photoTipsGood =

      'âœ… Lumière naturelle douce\n'

      'âœ… Visage propre, sans maquillage\n'

      'âœ… Photo nette, distance 20-30 cm\n'

      'âœ… Fond neutre';



  static const String photoTipsBad =

      'âŒ Pas de filtres ni retouches\n'

      'âŒ Pas de flash direct\n'

      'âŒ Pas de lunettes\n'

      'âŒ Éviter le mauvais éclairage';

}



