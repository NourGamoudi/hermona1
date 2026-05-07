import 'package:flutter/material.dart';







class AppLocalizations {



  final Locale locale;



  AppLocalizations(this.locale);







  static AppLocalizations of(BuildContext context) {



    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;



  }







  static const _localizedValues = {



    'fr': {



      'welcome_title': 'Révélez l\'éclat de votre Peau',



      'welcome_subtitle': 'L\'IA au service de votre équilibre hormonal',



      'welcome_desc': 'Analyse faciale 5 zones, suivi de cycle et routines expertes personnalisées.',



      'login': 'Se connecter',



      'register': 'Créer un compte',



      'email': 'Email',



      'password': 'Mot de passe',



      'forgot_password': 'Mot de passe oublié ?',



      'no_account': 'Pas encore de compte ? ',



      'already_account': 'Déjà un compte ? ',



      'home': 'Accueil',



      'profile': 'Profil',



      'chat': 'Chat',



      'prediction': 'Prédiction',



      'history': 'Historique',



      'settings': 'Paramètres',



      'logout': 'Déconnexion',



      'theme': 'Thème',



      'language': 'Langue',



      'color': 'Couleur principale',



      'terms': 'Conditions d\'utilisation',



      'chat_ia': 'Chat IA',



      'recommendations': 'Ma Routine',



      'daily_q': 'Questionnaire quotidien',



      'weekly_q': 'Questionnaire hebdomadaire',



      'personal_info': 'Informations personnelles',



      'skin_type': 'Type de peau',



      'acne_treatment': 'Traitement acné',



      'my_analyses': 'Mes analyses',



      'my_predictions': 'Mes prédictions',



      'forum': 'Forum',



      'messages': 'Messages',



      'section_profile': 'Informations Profil',



      'section_tracking': 'Mes Suivis',



      'section_history': 'Historique',



      'section_community': 'Communauté',



      'section_settings': 'Paramètres',



      'personal_info_sub': 'âge, IMC, etc.',



      'daily_q_done': 'Complété pour aujourd\'hui',



      'daily_q_todo': 'à remplir aujourd\'hui',



      'weekly_q_done': 'Déjà rempli cette semaine',



      'weekly_q_todo': 'Bilan de la semaine à faire',



      'logout_confirm_title': 'Déconnexion',



      'logout_confirm_desc': 'Voulez-vous vraiment vous déconnecter ?',



      'cancel': 'Annuler',



      'apply': 'Appliquer',



      'hello': 'Bonjour',



      'how_is_skin': 'Comment se sent ta peau aujourd\'hui ?',



      'risk': 'Risque',



      'latest_photo_analysis': 'Dernière Analyse Photo',



      'no_photo_analysis': 'Aucune Analyse Photo',



      'view_ia_details': 'Voir les détails de la détection IA',



      'take_first_photo': 'Prenez votre première photo',



      'my_questionnaires': 'Mes Questionnaires',



      'profile_info': 'Informations Profil',



      'manage_personal_data': 'Gérer vos données personnelles',



      'daily_tracking': 'Suivi Quotidien',



      'daily_tracking_subtitle': 'à remplir chaque jour',



      'weekly_review': 'Bilan Hebdomadaire',



      'weekly_review_subtitle': 'Analyse photo de la semaine',



      'cycle_details': 'Détails du Cycle',



      'day_in_cycle': 'jour de ton cycle',



      'average_cycle': 'Moyenne de tes cycles',



      'currently_in': 'Tu es actuellement en',



      'phase_influence': 'Cette phase influence l\'hydratation et la sensibilité de ta peau.',



      'close': 'Fermer',



      'today_is': 'Aujourd\'hui est le',



      'assistant': 'Assistant',



      'messagerie': 'Messagerie',



      'phase_menstrual': 'Ï°Å¸Å’¸ Phase Menstruelle',



      'phase_follicular': 'Ï°Å¸Å’¿ Phase Folliculaire',



      'phase_ovulatory': '✨ Phase Ovulatoire',



      'phase_luteal': 'Ï°Å¸Å’â„¢ Phase Lutéale',



      'phase_unknown': 'Phase inconnue',



      'login_welcome': 'Bienvenue ! Entrez vos identifiants.',



      'expert_subtitle': 'Votre expert beauté intelligent',



      'invalid_email': 'Email invalide',



      'min_password': 'Min. 6 caractères',



      'or': 'ou',



      'google_continue': 'Continuer avec Google',



      'reset_password': 'Réinitialiser le mot de passe',



      'enter_email': 'Votre email',



      'send': 'Envoyer',



      'email_sent': 'Email envoyé !',



      'register_welcome': 'Rejoignez notre communautéé beauté Ï°Å¸Å’¸',



      'required': 'Requis',



      'accept_terms': 'Veuillez accepter les conditions d\'utilisation',



      'i_accept': 'J\'accepte les ',



      'signup': 'S\'inscrire',



      'profile_hermona': 'Profil Hermona',



      'step': 'étape',



      'next': 'Suivant',



      'finish': 'Terminer',



      'personal_profile': 'Profil Personnel',



      'let_us_talk': 'Parlons un peu de toi.',



      'sopk_title': 'SOPK (Syndrome des Ovaires Polykystiques)',



      'yes': 'Oui',



      'no': 'Non',



      'unknown': 'Inconnu',



      'family_history_acne': 'Antécédents familiaux d\'acné',



      'smoker': 'Fumeuse',



      'alcohol_consumption': 'Consommation d\'alcool',



      'never': 'jamais',



      'occasional': 'occasionnel',



      'regular': 'régulier',



      'skin_profile': 'Profil Cutané',



      'skin_type_desc': 'Ton type de peau et tes sensibilités.',



      'what_skin_type': 'Quel est ton type de peau ?',



      'oily': 'grasse',



      'combination': 'mixte',



      'dry': 'sèche',



      'sensitive': 'sensible',



      'normal': 'normale',



      'acne_prone': 'acnéique',



      'known_allergies': 'Allergies cosmétiques connues :',



      'none': 'aucune',



      'perfumes': 'parfums',



      'preservatives': 'conservateurs',



      'cosmetic_alcohol': 'alcool cosmétique',



      'nickel': 'nickel',



      'sun_filters': 'filtres solaires',



      'retinol': 'rétinol',



      'aha_bha': 'AHA-BHA',



      'medical_profile': 'Profil Médical',



      'current_treatments': 'Tes traitements en cours.',



      'priority_recommendations': 'C\'est une priorité absolue pour nos recommandations.',



      'current_acne_treatment': 'Traitement acné actuel',



      'antibiotics': 'antibiotiques',



      'isotretinoin': 'isotrétinoïne',



      'topical_cream': 'crème topique',



      'current_hormonal_treatment': 'Traitement hormonal actuel',



      'pill': 'pilule',



      'implant': 'implant',



      'iud': 'stérilet',



      'current_routine': 'Routine Actuelle',



      'products_used': 'Quels produits utilises-tu ?',



      'morning': 'Le matin âËœàï¸',



      'evening': 'Le soir Ï°Å¸Å’â„¢',



      'no_product': 'Aucun produit',



      'gentle_cleanser': 'Nettoyant doux',



      'toner': 'Tonique',



      'vit_c_serum': 'Sérum Vitamine C',



      'moisturizer': 'Crème hydratante',



      'spf_indispensable': 'SPF (Indispensable)',



      'cleanser': 'Nettoyant',



      'makeup_remover': 'Démaquillant/Huile',



      'active_retinol': 'Actif (Rétinol/AHA)',



      'hydrating_serum': 'Sérum hydratant',



      'night_cream': 'Crème de nuit',



      'menstrual_cycle': 'Cycle Menstruel',



      'calculate_phase': 'Pour calculer ta phase actuelle.',



      'last_periods_date': 'Date des dernières règles',



      'last_3_cycles_duration': 'Durée des 3 derniers cycles (jours)',



      'daily_survey_title': 'SUIVI QUOTIDIEN',



      'daily_q_full_title': 'Ï°Å¸"”¹ Questionnaire Quotidien',



      'stress_label': 'Stress (1-10)',



      'sleep_duration_label': 'Sommeil - Durée (heures)',



      'sleep_quality_label': 'Sommeil - Qualité (1-10)',



      'hydration_label': 'Hydratation (verres d\'eau)',



      'spf_today': 'SPF appliqué aujourd\'hui ?',



      'diet_label': 'Alimentation :',



      'symptoms_today': 'Symptômes du jour :',



      'already_done_today': '✅ Vous avez déjé  rempli votre suivi pour aujourd\'hui.',



      'change_tap_edit': 'Si vous voulez changer, appuyez sur modifier en haut.',



      'update': 'Mettre é  jour',



      'send_btn': 'Envoyer',



      'sugar': 'sucre',



      'dairy': 'laitages',



      'fast_food': 'fast-food',



      'fruits': 'fruits',



      'balanced': 'équilibrée',



      'cramps': 'crampes',



      'bloating': 'ballonnements',



      'mood_swings': 'sautes d\'humeur',



      'fatigue': 'fatigue',



      'tender_breasts': 'seins sensibles',



      'headaches': 'maux de tête',



      'weekly_survey_title': 'CHAQUE SEMAINE',



      'weekly_q_full_title': 'Ï°Å¸"”¹ étape 3 : Bilan hebdomadaire',



      'face_photo_required': 'Ï°Å¸"¸ Photo de face requise',



      'face_photo_desc': 'Cette photo permet de suivre l\'évolution de votre acné chaque semaine.',



      'tap_to_take_photo': 'Cliquer pour prendre la photo',



      'makeup_label': '💄 Maquillage',



      'makeup_freq_week': 'Fréquence semaine',



      'makeup_type': 'Type',



      'makeup_removal_method': 'Démaquillage',



      'skincare_routine': 'Ï°Å¸§´ Routine de soin',



      'cleansing_freq': 'Fréquence nettoyage visage',



      'routine_followed': 'As-tu suivi la routine recommandée ?',



      'spf_this_week': 'Protection solaire cette semaine ?',



      'update_analyze': 'Mettre é  jour & Analyser',



      'send_analyze': 'Envoyer & Lancer l\'analyse',



      'every_day': 'tous les jours',



      '4_6_days': '4-6j',



      '2_3_days': '2-3j',



      '1_day': '1j',



      'full': 'complet',



      'moderate': 'modéré',



      'light': 'léger',



      'natural': 'naturel',



      'simple': 'simple',



      'partial': 'partiel',



      'rarely': 'rarement',



      'twice_day': '2x/jour',



      'once_day': '1x/jour',



      'partially': 'Partiellement',



      'sometimes': 'Parfois',



      'prediction_hermona': 'Prédiction Hermona',



      'ready_for_report': 'Prête pour ton bilan ?',



      'prediction_desc': 'Notre IA va analyser ton cycle, ton hygiène de vie et tes données pour prédire les risques d\'imperfections.',



      'start_ia_analysis': 'Lancer l\'analyse IA',



      'analysis_hermona': 'Analyse Hermona',



      'routine_tab': 'Routine',



      'avoid_tab': 'à éviter',



      'lifestyle_tab': 'Mode de vie',



      'new_analysis': 'Nouvelle analyse',



      'risk_today': 'Risque aujourd\'hui',



      'prevention': 'PRéVENTION',



      'balance': 'éQUILIBRE',



      'protection': 'PROTECTION',



      'day_3': 'J+3',



      'trend': 'Tendance',



      'cycle': 'Cycle',



      'why_this_score': 'Pourquoi ce score ?',



      'technical_factors': 'Facteurs Techniques (IA)',



      'hygiene_score': 'Score Hygiène',



      'recommended_routine': 'Ta Routine Recommandée',



      'to_avoid_desc': 'Ces éléments pourraient aggraver l\'inflammation en phase',



      'lifestyle_tips': 'Conseils personnalisés basés sur tes facteurs SHAP.',



      'take_photo': 'Prendre une photo',



      'choose_gallery': 'Choisir dans la galerie',



      'analysis_results': 'Rapport de Suivi Cutané',



      'severity_score': 'Score de sévérité',



      'zone_analysis': 'Analyse par zone du visage',



      'acne_types_detected': 'Types d\'acné détectés',



      'view_recommendations': 'Ma Routine Personnalisée ✨',



      'severity_normal': 'Normal',



      'severity_moderate': 'Modéré',



      'severity_severe': 'Sévère',



      'msg_normal': 'Votre peau semble saine. Continuez ainsi !',



      'msg_moderate': 'Pattern d\'acné modéré observé. Une routine de soin adaptée pourrait aider.',



      'msg_severe': 'Analyse montrant des signes importants. Nous recommandons de consulter un dermatologue.',



      'modify_weekly_report': 'Modifier mon bilan hebdomadaire',



      'error_first_name': 'Veuillez entrer votre prénom',



      'error_age': 'Veuillez entrer votre é¢ge',



      'error_imc': 'Veuillez entrer votre IMC',



      'error_skin_type': 'Veuillez choisir votre type de peau',



      'error_allergies': 'Veuillez choisir vos allergies ou "aucune"',



      'error_routine_morning': 'Veuillez choisir votre routine matin ou "Aucun produit"',



      'error_routine_evening': 'Veuillez choisir votre routine soir ou "Aucun produit"',



      'error_cycle_duration': 'Veuillez remplir les durées de cycles',



      'my_recommendations': 'Ma Routine Expert',



      'morning_tab': 'Matin',



      'evening_tab': 'Soir',



      'diet_tab': 'Alimentation',



      'prevention_tab': 'Prévention',



      'retry': 'Réessayer',



      'no_rec_found': 'Aucune recommandation trouvée',



      'hygiene_label': 'HYGIéË†NE',



      'risk_j3': 'RISQUE J+3',



      'morning_routine': 'Routine Matinale',



      'evening_routine': 'Routine du Soir',



      'protection_glow': 'Protection & éclat',



      'repair_treatment': 'Réparation & Traitement',



      'recommended_brands': 'MARQUES CONSEILLéES',



      'inner_glow': 'Rayonner de l\'intérieur',



      'avoid_relapse': 'éviter les récidives',



      'error_load_rec': 'Impossible de charger vos recommandations. Vérifiez votre connexion au serveur.',



      'edit': 'Modifier',



      'my_history': 'Mon historique',



      'analyses_tab': 'Analyses',



      'routines_tab': 'Routines',



      'predictions_tab': 'Prédictions',



      'daily_tab': 'Quotidien',



      'weekly_tab': 'Hebdo',



      'chats_tab': 'Chats',



      'no_analysis': 'Aucune analyse',



      'analyze_skin_home': 'Analysez votre peau depuis l\'accueil',



      'analysis_id': 'Analyse #',



      'no_recommendation': 'Aucune recommandation',



      'analyze_skin_rec': 'Analysez votre peau pour obtenir des recommandations',



      'personalized_routine': 'Routine personnalisée',



      'duration': 'Durée',



      'no_prediction': 'Aucune prédiction',



      'anticipate_outbreaks': 'Utilisez la prédiction pour anticiper les poussées',



      'prediction_id': 'Prédiction #',



      'low': 'Faible',



      'medium': 'Moyen',



      'high': 'élevé',



      'no_daily_survey': 'Aucun suivi quotidien',



      'fill_daily_survey': 'Remplissez votre suivi chaque jour',



      'no_weekly_survey': 'Aucun bilan hebdomadaire',



      'fill_weekly_survey': 'Faites votre bilan chaque semaine',



      'week_label': 'Semaine',



      'no_conversation': 'Aucune conversation',



      'ask_ia_assistant': 'Posez vos questions é  l\'assistante IA',



      'posts': 'Posts',



      'terms_title': 'Conditions d\'utilisation',



      'terms_header': 'Hermona âà" Conditions Générales',



      'terms_obj_title': '1. Objet',



      'terms_obj_desc': 'Hermona est une application d\'aide é  la détection d\'acné et de recommandation de soins. Elle ne remplace en aucun cas un avis médical professionnel.',



      'terms_data_title': '2. Données personnelles',



      'terms_data_desc': 'Vos images sont collectées uniquement pour l\'analyse IA, stockées de manière sécurisée et ne sont jamais partagées avec des tiers sans votre consentement.',



      'terms_ia_title': '3. Intelligence Artificielle',



      'terms_ia_desc': 'Les résultats fournis par l\'IA sont indicatifs. Pour tout problème dermatologique sérieux, consultez un médecin ou dermatologue.',



      'terms_forum_title': '4. Forum anonyme',



      'terms_forum_desc': 'Le forum est anonyme. Vous êtes responsable des contenus publiés. Tout contenu inapproprié peut être signalé et supprimé.',



      'terms_msg_title': '5. Messagerie privée',



      'terms_msg_desc': 'La messagerie est anonyme. Ne partagez jamais vos informations personnelles (nom, adresse, téléphone).',



      'terms_report_title': '6. Signalements',



      'terms_report_desc': 'Tout contenu signalé 3 fois est automatiquement masqué en attente de modération.',



      'terms_mod_title': '7. Modifications',



      'terms_mod_desc': 'Nous nous réservons le droit de modifier ces conditions é  tout moment avec notification préalable.',



      'terms_medical_disclaimer': 'âÅ¡”¢ï¸ Hermona ne fournit pas de diagnostics médicaux. Consultez toujours un professionnel de santé pour des problèmes dermatologiques.',



      'notification_center': 'Centre de Notifications',



      'notifications_connect': 'Connectez-vous pour voir vos notifications',



      'no_message': 'Aucun message',



      'no_alert': 'Aucune alerte',



      'message_desc': 'Vos messages privés apparaé®tront ici.',



      'alert_desc': 'Vos alertes de risque et rappels apparaé®tront ici.',



      'error_loading': 'Erreur de chargement',



      'alerts': 'Alertes',



      'sucre': 'sucre',



      'laitages': 'laitages',



      'équilibrée': 'équilibrée',



      'crampes': 'crampes',



      'ballonnements': 'ballonnements',



      'sautes d\'humeur': 'sautes d\'humeur',



      'seins sensibles': 'seins sensibles',



      'maux de tête': 'maux de tête',



      'tous les jours': 'tous les jours',



      '4-6j': '4-6j',



      '2-3j': '2-3j',



      '1j': '1j',



      'jamais': 'jamais',



      'complet': 'complet',



      'modéré': 'modéré',



      'léger': 'léger',



      'naturel': 'naturel',



      'partiel': 'partiel',



      'rarement': 'rarement',



      '2x/jour': '2x/jour',



      '1x/jour': '1x/jour',



      'oui': 'oui',



      'non': 'non',



      'Tous les jours': 'Tous les jours',



      'Parfois': 'Parfois',



      'Jamais': 'Jamais',



      'Partiellement': 'Partiellement',



      'parfois': 'parfois',



      'partiellement': 'partiellement',



      'grasse': 'grasse',



      'mixte': 'mixte',



      'sèche': 'sèche',



      'sensible': 'sensible',



      'normale': 'normale',



      'acnéique': 'acnéique',



      'aucune': 'aucune',



      'parfums': 'parfums',



      'conservateurs': 'conservateurs',



      'alcool cosmétique': 'alcool cosmétique',



      'filtres solaires': 'filtres solaires',



      'rétinol': 'rétinol',



      'AHA-BHA': 'AHA-BHA',



      'pilule': 'pilule',



      'stérilet': 'stérilet',



      'aucun': 'aucun',



      'antibiotiques': 'antibiotiques',



      'isotrétinoïne': 'isotrétinoïne',



      'crème topique': 'crème topique',



      'Aucun produit': 'Aucun produit',



      'Nettoyant doux': 'Nettoyant doux',



      'Tonique': 'Tonique',



      'Sérum Vitamine C': 'Sérum Vitamine C',



      'Crème hydratante': 'Crème hydratante',



      'SPF (Indispensable)': 'SPF (Indispensable)',



      'Démaquillant/Huile': 'Démaquillant/Huile',



      'Nettoyant': 'Nettoyant',



      'Actif (Rétinol/AHA)': 'Actif (Rétinol/AHA)',



      'Sérum hydratant': 'Sérum hydratant',



      'Crème de nuit': 'Crème de nuit',



      'error_pseudo': 'Veuillez choisir un pseudonyme',



      'pseudo_forum': 'Pseudonyme (pour le forum)',



      'imc_label': 'IMC',



      'error_face_photo': 'Veuillez prendre une photo de face pour l\'analyse.',



      'skin_analysis_progress': 'Analyse de votre peau en cours...',



      'error_saving': 'Erreur lors de l\'enregistrement',



      'firestore_error': 'Erreur Firestore',



      'trends_title': 'évolution & Tendances',



      'acne_evolution': 'évolution de l\'Acné',



      'acne_evolution_sub': 'Score de sévérité (0-100)',



      'risk_evolution': 'Risque d\'Imperfections',



      'risk_evolution_sub': 'Probabilité prédite (%)',



      'trends_filter': 'Filtrer par période',



      'days_count': '{} jours',



      'expert_tip': 'Conseil d\'expert',



      'trends_tip_desc': 'Une courbe descendante indique une amélioration de l\'état de votre peau. Continuez votre routine Hermona !',



      'not_enough_data': 'Pas assez de données pour cette période.',



    },



    'en': {



      'welcome_title': 'Reveal Your Skin\'s Glow',



      'welcome_subtitle': 'AI-Powered Hormonal Acne Care',



      'welcome_desc': '5-zone facial analysis, cycle tracking, and personalized expert routines.',



      'login': 'Log In',



      'register': 'Create Account',



      'email': 'Email',



      'password': 'Password',



      'forgot_password': 'Forgot password?',



      'no_account': "Don't have an account? ",



      'already_account': 'Already have an account? ',



      'home': 'Home',



      'profile': 'Profile',



      'chat': 'Chat',



      'prediction': 'Prediction',



      'history': 'History',



      'settings': 'Settings',



      'logout': 'Log Out',



      'theme': 'Theme',



      'language': 'Language',



      'color': 'Primary Color',



      'terms': 'Terms of Use',



      'chat_ia': 'AI Chat',



      'recommendations': 'Routine',



      'daily_q': 'Daily Questionnaire',



      'weekly_q': 'Weekly Questionnaire',



      'personal_info': 'Personal Information',



      'skin_type': 'Skin Type',



      'acne_treatment': 'Acne Treatment',



      'my_analyses': 'My Analyses',



      'my_predictions': 'My Predictions',



      'forum': 'Forum',



      'messages': 'Messages',



      'section_profile': 'Profile Information',



      'section_tracking': 'My Tracking',



      'section_history': 'History',



      'section_community': 'Community',



      'section_settings': 'Settings',



      'personal_info_sub': 'Age, BMI, etc.',



      'daily_q_done': 'Completed for today',



      'daily_q_todo': 'To fill out today',



      'weekly_q_done': 'Already filled this week',



      'weekly_q_todo': 'Weekly review to do',



      'logout_confirm_title': 'Logout',



      'logout_confirm_desc': 'Do you really want to log out?',



      'cancel': 'Cancel',



      'apply': 'Apply',



      'hello': 'Hello',



      'how_is_skin': 'How is your skin feeling today?',



      'risk': 'Risk',



      'latest_photo_analysis': 'Latest Photo Analysis',



      'no_photo_analysis': 'No Photo Analysis',



      'view_ia_details': 'View AI detection details',



      'take_first_photo': 'Take your first photo',



      'my_questionnaires': 'My Questionnaires',



      'profile_info': 'Profile Information',



      'manage_personal_data': 'Manage your personal data',



      'daily_tracking': 'Daily Tracking',



      'daily_tracking_subtitle': 'To be filled out every day',



      'weekly_review': 'Weekly Review',



      'weekly_review_subtitle': 'Weekly photo analysis',



      'cycle_details': 'Cycle Details',



      'day_in_cycle': 'day of your cycle',



      'average_cycle': 'Average of your cycles',



      'currently_in': 'You are currently in',



      'phase_influence': 'This phase influences the hydration and sensitivity of your skin.',



      'close': 'Close',



      'today_is': 'Today is the',



      'assistant': 'Assistant',



      'messagerie': 'Messaging',



      'phase_menstrual': 'Ï°Å¸Å’¸ Menstrual Phase',



      'phase_follicular': 'Ï°Å¸Å’¿ Follicular Phase',



      'phase_ovulatory': '✨ Ovulatory Phase',



      'phase_luteal': 'Ï°Å¸Å’â„¢ Luteal Phase',



      'phase_unknown': 'Unknown Phase',



      'login_welcome': 'Welcome back! Enter your credentials.',



      'expert_subtitle': 'Your smart beauty expert',



      'invalid_email': 'Invalid email',



      'min_password': 'Min. 6 characters',



      'or': 'or',



      'google_continue': 'Continue with Google',



      'reset_password': 'Reset password',



      'enter_email': 'Your email',



      'send': 'Send',



      'email_sent': 'Email sent!',



      'register_welcome': 'Join our beauty community Ï°Å¸Å’¸',



      'required': 'Required',



      'accept_terms': 'Please accept the terms of use',



      'i_accept': 'I accept the ',



      'signup': 'Sign Up',



      'first_name': 'First Name',



      'last_name': 'Last Name',



      'confirm_password': 'Confirm Password',



      'passwords_dont_match': 'Passwords do not match',



      'profile_hermona': 'Hermona Profile',



      'step': 'Step',



      'next': 'Next',



      'finish': 'Finish',



      'personal_profile': 'Personal Profile',



      'let_us_talk': 'Let\'s talk a bit about you.',



      'sopk_title': 'PCOS (Polycystic Ovary Syndrome)',



      'yes': 'Yes',



      'no': 'No',



      'unknown': 'Unknown',



      'family_history_acne': 'Family history of acne',



      'smoker': 'Smoker',



      'alcohol_consumption': 'Alcohol consumption',



      'never': 'never',



      'occasional': 'occasional',



      'regular': 'regular',



      'skin_profile': 'Skin Profile',



      'skin_type_desc': 'Your skin type and sensitivities.',



      'what_skin_type': 'What is your skin type?',



      'oily': 'oily',



      'combination': 'combination',



      'dry': 'dry',



      'sensitive': 'sensitive',



      'normal': 'normal',



      'acne_prone': 'acne-prone',



      'known_allergies': 'Known cosmetic allergies:',



      'none': 'none',



      'perfumes': 'perfumes',



      'preservatives': 'preservatives',



      'cosmetic_alcohol': 'cosmetic alcohol',



      'nickel': 'nickel',



      'sun_filters': 'sun filters',



      'retinol': 'retinol',



      'aha_bha': 'AHA-BHA',



      'medical_profile': 'Medical Profile',



      'current_treatments': 'Your current treatments.',



      'priority_recommendations': 'This is an absolute priority for our recommendations.',



      'current_acne_treatment': 'Current acne treatment',



      'antibiotics': 'antibiotics',



      'isotretinoin': 'isotretinoin',



      'topical_cream': 'topical cream',



      'current_hormonal_treatment': 'Current hormonal treatment',



      'pill': 'pill',



      'implant': 'implant',



      'iud': 'IUD',



      'current_routine': 'Current Routine',



      'products_used': 'Which products do you use?',



      'morning': 'Morning âËœàï¸',



      'evening': 'Evening Ï°Å¸Å’â„¢',



      'no_product': 'No product',



      'gentle_cleanser': 'Gentle cleanser',



      'toner': 'Toner',



      'vit_c_serum': 'Vitamin C Serum',



      'moisturizer': 'Moisturizer',



      'spf_indispensable': 'SPF (Essential)',



      'cleanser': 'Cleanser',



      'makeup_remover': 'Makeup Remover/Oil',



      'active_retinol': 'Active (Retinol/AHA)',



      'hydrating_serum': 'Hydrating Serum',



      'night_cream': 'Night cream',



      'menstrual_cycle': 'Menstrual Cycle',



      'calculate_phase': 'To calculate your current phase.',



      'last_periods_date': 'Date of last periods',



      'last_3_cycles_duration': 'Duration of the last 3 cycles (days)',



      'daily_survey_title': 'DAILY TRACKING',



      'daily_q_full_title': 'Ï°Å¸"”¹ Daily Questionnaire',



      'stress_label': 'Stress (1-10)',



      'sleep_duration_label': 'Sleep - Duration (hours)',



      'sleep_quality_label': 'Sleep - Quality (1-10)',



      'hydration_label': 'Hydration (glasses of water)',



      'spf_today': 'SPF applied today?',



      'diet_label': 'Diet:',



      'symptoms_today': 'Symptoms of the day:',



      'already_done_today': '✅ You have already filled out your tracking for today.',



      'change_tap_edit': 'If you want to change, tap edit at the top.',



      'update': 'Update',



      'send_btn': 'Send',



      'sugar': 'sugar',



      'dairy': 'dairy',



      'fast_food': 'fast-food',



      'fruits': 'fruits',



      'balanced': 'balanced',



      'cramps': 'cramps',



      'bloating': 'bloating',



      'mood_swings': 'mood swings',



      'fatigue': 'fatigue',



      'tender_breasts': 'tender breasts',



      'headaches': 'headaches',



      'weekly_survey_title': 'EVERY WEEK',



      'weekly_q_full_title': 'Ï°Å¸"”¹ Step 3: Weekly Review',



      'face_photo_required': 'Ï°Å¸"¸ Face photo required',



      'face_photo_desc': 'This photo allows tracking the evolution of your acne every week.',



      'tap_to_take_photo': 'Tap to take photo',



      'makeup_label': '💄 Makeup',



      'makeup_freq_week': 'Frequency per week',



      'makeup_type': 'Type',



      'makeup_removal_method': 'Makeup removal',



      'skincare_routine': 'Ï°Å¸§´ Skincare routine',



      'cleansing_freq': 'Face cleansing frequency',



      'routine_followed': 'Did you follow the recommended routine?',



      'spf_this_week': 'Sun protection this week?',



      'update_analyze': 'Update & Analyze',



      'send_analyze': 'Send & Start analysis',



      'every_day': 'every day',



      '4_6_days': '4-6d',



      '2_3_days': '2-3d',



      '1_day': '1d',



      'full': 'full',



      'moderate': 'moderate',



      'light': 'light',



      'natural': 'natural',



      'simple': 'simple',



      'partial': 'partial',



      'rarely': 'rarely',



      'twice_day': '2x/day',



      'once_day': '1x/day',



      'partially': 'Partially',



      'sometimes': 'Sometimes',



      'prediction_hermona': 'Hermona Prediction',



      'ready_for_report': 'Ready for your report?',



      'prediction_desc': 'Our AI will analyze your cycle, lifestyle and data to predict the risks of imperfections.',



      'start_ia_analysis': 'Start AI analysis',



      'analysis_hermona': 'Hermona Analysis',



      'routine_tab': 'Routine',



      'avoid_tab': 'To avoid',



      'lifestyle_tab': 'Lifestyle',



      'new_analysis': 'New analysis',



      'risk_today': 'Risk today',



      'prevention': 'PREVENTION',



      'balance': 'BALANCE',



      'protection': 'PROTECTION',



      'day_3': 'D+3',



      'trend': 'Trend',



      'cycle': 'Cycle',



      'why_this_score': 'Why this score?',



      'technical_factors': 'Technical Factors (AI)',



      'hygiene_score': 'Hygiene Score',



      'recommended_routine': 'Your Recommended Routine',



      'to_avoid_desc': 'These elements could worsen inflammation in phase',



      'lifestyle_tips': 'Personalized tips based on your SHAP factors.',



      'take_photo': 'Take a photo',



      'choose_gallery': 'Choose from gallery',



      'analysis_results': 'Analysis Results',



      'severity_score': 'Severity Score',



      'zone_analysis': 'Zone Analysis',



      'acne_types_detected': 'Acne types detected',



      'view_recommendations': 'View my recommendations Ï°Å¸Å’Å¸',



      'severity_normal': 'Normal',



      'severity_moderate': 'Moderate',



      'severity_severe': 'Severe',



      'msg_normal': 'Your skin is healthy! Maintain your routine.',



      'msg_moderate': 'Moderate acne detected. Adapted treatment is recommended.',



      'msg_severe': 'Severe acne. Consult a dermatologist in addition to skincare.',



      'modify_weekly_report': 'Modify my weekly report',



      'error_first_name': 'Please enter your first name',



      'error_age': 'Please enter your age',



      'error_imc': 'Please enter your BMI',



      'error_skin_type': 'Please choose your skin type',



      'error_allergies': 'Please choose your allergies or "none"',



      'error_routine_morning': 'Please choose your morning routine or "No product"',



      'error_routine_evening': 'Please choose your evening routine or "No product"',



      'error_cycle_duration': 'Please fill in the cycle durations',



      'my_recommendations': 'My Expert Routine',



      'morning_tab': 'Morning',



      'evening_tab': 'Evening',



      'diet_tab': 'Diet',



      'prevention_tab': 'Prevention',



      'retry': 'Retry',



      'no_rec_found': 'No recommendation found',



      'hygiene_label': 'HYGIENE',



      'risk_j3': 'RISK D+3',



      'morning_routine': 'Morning Routine',



      'evening_routine': 'Evening Routine',



      'protection_glow': 'Protection & Glow',



      'repair_treatment': 'Repair & Treatment',



      'recommended_brands': 'RECOMMENDED BRANDS',



      'inner_glow': 'Inner Glow',



      'avoid_relapse': 'Avoid Relapse',



      'error_load_rec': 'Unable to load your recommendations. Check your server connection.',



      'edit': 'Edit',



      'my_history': 'My History',



      'analyses_tab': 'Analyses',



      'routines_tab': 'Routines',



      'predictions_tab': 'Predictions',



      'daily_tab': 'Daily',



      'weekly_tab': 'Weekly',



      'chats_tab': 'Chats',



      'no_analysis': 'No analysis',



      'analyze_skin_home': 'Analyze your skin from the home screen',



      'analysis_id': 'Analysis #',



      'no_recommendation': 'No recommendation',



      'analyze_skin_rec': 'Analyze your skin to get recommendations',



      'personalized_routine': 'Personalized routine',



      'duration': 'Duration',



      'no_prediction': 'No prediction',



      'anticipate_outbreaks': 'Use prediction to anticipate outbreaks',



      'prediction_id': 'Prediction #',



      'low': 'Low',



      'medium': 'Medium',



      'high': 'High',



      'no_daily_survey': 'No daily survey',



      'fill_daily_survey': 'Fill out your tracking every day',



      'no_weekly_survey': 'No weekly review',



      'fill_weekly_survey': 'Do your review every week',



      'week_label': 'Week',



      'no_conversation': 'No conversation',



      'ask_ia_assistant': 'Ask your questions to the AI assistant',



      'posts': 'Posts',



      'terms_title': 'Terms of Use',



      'terms_header': 'Hermona âà" General Terms',



      'terms_obj_title': '1. Purpose',



      'terms_obj_desc': 'Hermona is an application to help in acne detection and skincare recommendation. It does not replace professional medical advice.',



      'terms_data_title': '2. Personal data',



      'terms_data_desc': 'Your images are collected only for AI analysis, stored securely and never shared with third parties without your consent.',



      'terms_ia_title': '3. Artificial Intelligence',



      'terms_ia_desc': 'Results provided by AI are indicative. For any serious dermatological problem, consult a doctor or dermatologist.',



      'terms_forum_title': '4. Anonymous forum',



      'terms_forum_desc': 'The forum is anonymous. You are responsible for the published content. Any inappropriate content can be reported and deleted.',



      'terms_msg_title': '5. Private messaging',



      'terms_msg_desc': 'Messaging is anonymous. Never share your personal information (name, address, phone).',



      'terms_report_title': '6. Reports',



      'terms_report_desc': 'Any content reported 3 times is automatically hidden pending moderation.',



      'terms_mod_title': '7. Modifications',



      'terms_mod_desc': 'We reserve the right to modify these terms at any time with prior notification.',



      'terms_medical_disclaimer': 'âÅ¡”¢ï¸ Hermona does not provide medical diagnoses. Always consult a healthcare professional for dermatological problems.',



      'notification_center': 'Notification Center',



      'notifications_connect': 'Log in to see your notifications',



      'no_message': 'No messages',



      'no_alert': 'No alerts',



      'message_desc': 'Your private messages will appear here.',



      'alert_desc': 'Your risk alerts and reminders will appear here.',



      'error_loading': 'Loading error',



      'alerts': 'Alerts',



      'sucre': 'sugar',



      'laitages': 'dairy',



      'équilibrée': 'balanced',



      'crampes': 'cramps',



      'ballonnements': 'bloating',



      'sautes d\'humeur': 'mood swings',



      'seins sensibles': 'tender breasts',



      'maux de tête': 'headaches',



      'tous les jours': 'every day',



      '4-6j': '4-6d',



      '2-3j': '2-3d',



      '1j': '1d',



      'jamais': 'never',



      'complet': 'full',



      'modéré': 'moderate',



      'léger': 'light',



      'naturel': 'natural',



      'partiel': 'partial',



      'rarement': 'rarely',



      '2x/jour': '2x/day',



      '1x/jour': '1x/day',



      'oui': 'yes',



      'non': 'no',



      'Tous les jours': 'Every day',



      'Parfois': 'Sometimes',



      'Jamais': 'Never',



      'Partiellement': 'Partially',



      'parfois': 'sometimes',



      'partiellement': 'partially',



      'grasse': 'oily',



      'mixte': 'combination',



      'sèche': 'dry',



      'sensible': 'sensitive',



      'normale': 'normal',



      'acnéique': 'acne-prone',



      'aucune': 'none',



      'parfums': 'perfumes',



      'conservateurs': 'preservatives',



      'alcool cosmétique': 'cosmetic alcohol',



      'filtres solaires': 'sun filters',



      'rétinol': 'retinol',



      'AHA-BHA': 'AHA-BHA',



      'pilule': 'pill',



      'stérilet': 'IUD',



      'aucun': 'none',



      'antibiotiques': 'antibiotics',



      'isotrétinoïne': 'isotretinoin',



      'crème topique': 'topical cream',



      'Aucun produit': 'No product',



      'Nettoyant doux': 'Gentle cleanser',



      'Tonique': 'Toner',



      'Sérum Vitamine C': 'Vitamin C Serum',



      'Crème hydratante': 'Moisturizer',



      'SPF (Indispensable)': 'SPF (Essential)',



      'Démaquillant/Huile': 'Makeup Remover/Oil',



      'Nettoyant': 'Cleanser',



      'Actif (Rétinol/AHA)': 'Active (Retinol/AHA)',



      'Sérum hydratant': 'Hydrating Serum',



      'Crème de nuit': 'Night cream',



      'error_pseudo': 'Please choose a pseudonym',



      'pseudo_forum': 'Pseudonym (for the forum)',



      'imc_label': 'BMI',



      'error_face_photo': 'Please take a face photo for analysis.',



      'skin_analysis_progress': 'Skin analysis in progress...',



      'error_saving': 'Error during saving',



      'firestore_error': 'Firestore Error',



      'trends_title': 'Evolution & Trends',



      'acne_evolution': 'Acne Evolution',



      'acne_evolution_sub': 'Severity score (0-100)',



      'risk_evolution': 'Blemish Risk',



      'risk_evolution_sub': 'Predicted probability (%)',



      'trends_filter': 'Filter by period',



      'days_count': '{} days',



      'expert_tip': 'Expert Tip',



      'trends_tip_desc': 'A downward curve indicates an improvement in your skin condition. Keep up your Hermona routine!',



      'not_enough_data': 'Not enough data for this period.',



    },



  };







  String translate(String key) {



    return _localizedValues[locale.languageCode]?[key] ?? key;



  }







  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();



}







class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {



  const _AppLocalizationsDelegate();







  @override



  bool isSupported(Locale locale) => ['fr', 'en'].contains(locale.languageCode);







  @override



  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);







  @override



  bool shouldReload(_AppLocalizationsDelegate old) => false;



}