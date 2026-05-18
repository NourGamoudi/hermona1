import 'package:flutter/material.dart';





class AppLocalizations {

  final Locale locale;

  AppLocalizations(this.locale) {
    debugPrint("DEBUG AUDIT: AppLocalizations INSTANCE CREATED for locale: ${locale.languageCode}");
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = {
    'fr': {
      'welcome_title_long': 'Révélez l\'éclat de votre Peau',
      'welcome_subtitle_long': 'L\'IA au service de votre équilibre hormonal',
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
      'continue': 'CONTINUER',
      'finish': 'TERMINER LE BILAN',
      'cancel': 'Annuler',
      'camera': 'Caméra',
      'gallery': 'Galerie',
      'back': 'Retour',
      'save': 'Enregistrer',
      'loading': 'Chargement...',
      'error_occurred': 'Une erreur est survenue',
      'personal_info_required': 'Veuillez remplir toutes vos informations personnelles.',
      'customize_hermona': 'Personnaliser Hermona',
      'apply': 'Appliquer',

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
      'personalization': 'Personnalisation',
      'dark_theme': 'Thème Sombre',
      'enable_disable': 'Activer/Désactiver',
      'brand_color': 'Couleur de Marque',
      'stay': 'RESTER',
      'leave': 'QUITTER',
      'analyses': 'Analyses',
      'risks': 'Risques',
      'mes_informations': 'Mes Informations',
      'detection_results_sub': 'Résultats de détection',
      'ai_history_sub': 'Historique AI',
      'assistant_messages_sub': 'Messages assistante',
      'age_label': 'Âge',
      'score_ia': 'Score IA',
      'risk_high': 'Élevé',
      'risk_medium': 'Modéré',
      'risk_low': 'Faible',
      'no_routine_available': 'Aucune routine disponible',
      'start_analysis_btn': 'Démarrer l\'analyse',
      'predictive_report_title': 'Bilan Prédictif',
      'predictive_analysis': 'Analyse Prédictive',
      'predictive_desc': 'Prédit tes futurs risques d\'acné basés sur ton cycle, ton hygiène et tes habitudes.',
      'launch_ia_analysis': 'LANCER L\'ANALYSE IA',
      'ai_working_desc': 'L\'IA analyse tes données pour un bilan précis...',
      'hermona_report': 'Rapport Hermona',
      'chat_private_title': 'Messagerie Privée',
      'analysis_tab_upper': 'ANALYSE',
      'new_scan': 'NOUVEAU SCAN',
      'estimated_risk': 'Risque Estimé',
      'risk_j3_label': 'RISQUE J+3',
      'increasing': 'EN HAUSSE',
      'stable': 'STABLE',
      'alerts_vigilance': 'Alertes & Vigilance',
      'alert_j3_title': 'Vigilance : Poussée à J+3',
      'alert_j3_desc': 'Une hausse du risque est prévue d\'ici 3 jours. Anticipez avec votre routine.',
      'alert_spf_title': 'Protection Solaire Manquante',
      'alert_spf_desc': 'L\'absence de SPF aggrave l\'inflammation et les marques résiduelles.',
      'alert_routine_title': 'Observance de Routine',
      'alert_routine_desc': 'La régularité est indispensable pour stabiliser votre peau.',
      'alert_cleansing_title': 'Nettoyage Cutané',
      'alert_cleansing_desc': 'Un nettoyage trop rare favorise l\'obstruction des pores par le sébum.',
      'influence_factors': 'Facteurs d\'Influence',
      'start_analyses_evolution': 'Commencez vos analyses pour voir votre évolution',
      'severity': 'Sévérité',
      'tap_for_details': 'Appuyez pour voir le détail complet',
      'my_routine_title': 'MA ROUTINE',
      'ai_analysis': 'ANALYSE IA',
      'hygiene': 'Hygiène',
      'pcos': 'SOPK',
      'hormonal_acne': 'Acné Hormonale',
      'cleansing_frequency': 'Fréquence Nettoyage',
      'diet': 'Alimentation',
      'stress': 'Stress',
      'sleep': 'Sommeil',
      'hormonal_cycle': 'Cycle Hormonal',
      'pollution': 'Pollution',
      'uv': 'Rayons UV',
      'phase_menstrual_info': 'Phase Menstruelle',
      'phase_follicular_info': 'Phase Folliculaire',
      'phase_ovulatory_info': 'Phase Ovulatoire',
      'phase_luteal_info': 'Phase Lutéale',
      'based_on_cycle_analysis': 'Basé sur l\'analyse de ton cycle.',
      'top_factor_impact': 'Facteur principal : ',
      'routine_complete': 'Ta routine est exemplaire !',
      'good_habits_reinforce': 'Bonnes habitudes, continue !',
      'improvement_points': 'Points d\'amélioration détectés.',
      'morning_short': 'Matin',
      'evening_short': 'Soir',
      'lifestyle_short': 'Vie',
      'step_label': 'Étape',
      'strategy_protection': 'PROTECTION & RÉPARATION',
      'strategy_equilibrium': 'ÉQUILIBRE & PRÉVENTION',
      'strategy_prevention': 'PRÉVENTION ACTIVE',
      'adopted_strategy': 'STRATÉGIE ADOPTÉE',
      'alternative_label': 'Alternative possible : ',
      'high': 'Élevé',
      'medium': 'Moyen',
      'low': 'Faible',
      'option_yes': 'Oui',
      'option_no': 'Non',
      'option_unknown': 'Inconnu',
      'freq_never': 'Jamais',
      'freq_occasionally': 'Occasionnel',
      'freq_daily': 'Quotidien',
      'makeup_light': 'Léger',
      'makeup_medium': 'Moyen',
      'makeup_full': 'Couvrant',
      'removal_micellar': 'Eau micellaire',
      'removal_oil': 'Huile/Baume',
      'removal_gel': 'Gel nettoyant',
      'cleans_twice': 'Matin et soir',
      'cleans_once': 'Soir uniquement',
      'routine_full': '100%',
      'routine_partial': 'Partiellement',
      'routine_rarely': 'Rarement',
      'spf_always': 'Tous les jours',
      'spf_sometimes': 'Quelques jours',
      'skin_grasse': 'Grasse',
      'skin_mixte': 'Mixte',
      'skin_seche': 'Sèche',
      'skin_sensible': 'Sensible',
      'skin_normale': 'Normale',
      'skin_acneique': 'Acnéique',
      'allergy_none': 'Aucune',
      'allergy_perfume': 'Parfums',
      'allergy_preservatives': 'Conservateurs',
      'allergy_alcohol': 'Alcool cosmétique',
      'allergy_nickel': 'Nickel',
      'allergy_sunscreen': 'Filtres solaires',
      'allergy_retinol': 'Rétinol',
      'allergy_aha_bha': 'AHA-BHA',
      'hormonal_pill': 'Pilule',
      'hormonal_implant': 'Implant',
      'hormonal_iud': 'Stérilet',
      'hormonal_none': 'Aucun',
      'treat_antibiotics': 'Antibiotiques',
      'treat_isotretinoin': 'Isotrétinoïne',
      'treat_topical': 'Crème topique',
      'treat_none': 'Aucun',
      'prod_none': 'Aucun produit',
      'prod_cleanser': 'Nettoyant doux',
      'prod_tonic': 'Tonique',
      'prod_vit_c': 'Sérum Vitamine C',
      'prod_moisturizer': 'Crème hydratante',
      'prod_spf': 'SPF',
      'prod_makeup_remover': 'Démaquillant',
      'prod_retinol': 'Actif (Rétinol)',
      'prod_hydrating_serum': 'Sérum hydratant',
      'prod_night_cream': 'Crème de nuit',
      
      // Why explanations (Rationale)
      'prod_makeup_remover_why': 'L\'huile attire le sébum et dissout le SPF efficacement sans agresser la peau mixte ou grasse.',
      'prod_cleanser_why': 'Un nettoyage doux préserve le film hydrolipidique tout en éliminant les bactéries.',
      'prod_moisturizer_why': 'Une peau bien hydratée régule mieux sa production de sébum et cicatrise plus vite.',
      'prod_spf_why': 'Le soleil oxyde le sébum et fixe les marques rouges/brunes de l\'acné. C\'est ton meilleur anti-âge.',
      'prod_retinol_why': 'Le rétinol accélère le renouvellement cellulaire pour lisser le grain de peau et réduire les imperfections.',
      'prod_hydrating_serum_why': 'Apporte une dose d\'eau intense pour calmer l\'inflammation et repulper la peau.',
      'why_this_choice': 'Pourquoi ce choix ?',
      
      // Daily Questionnaire
      'daily_title': 'Bilan Quotidien',
      'daily_header_title': 'Suivi Bien-être',
      'daily_header_sub': 'Tes données permettent à l\'IA d\'affiner ses prédictions.',
      'stress_level': 'Niveau de Stress',
      'sleep_hours': 'Heures de Sommeil',
      'hydration_glasses': 'Hydratation (Verres)',
      'spf_protection': 'Protection SPF appliquée',
      'daily_diet': 'Alimentation du jour',
      'symptoms_felt': 'Symptômes ressentis',
      'analyze_day': 'ANALYSER MA JOURNÉE',
      'diet_balanced': 'équilibrée',
      'diet_sugar': 'sucre',
      'diet_dairy': 'laitages',
      'diet_fastfood': 'fast-food',
      'diet_fruits': 'fruits',
      'symptom_none': 'aucun',
      'symptom_cramps': 'crampes',
      'symptom_bloating': 'ballonnements',
      'symptom_mood': 'sautes d\'humeur',
      'symptom_fatigue': 'fatigue',
      'symptom_breasts': 'seins sensibles',
      'symptom_headache': 'maux de tête',
      'error_diet_required': 'Veuillez sélectionner votre alimentation du jour.',
      'error_symptoms_required': 'Veuillez sélectionner vos symptômes (ou "aucun").',
      'daily_saved': 'Bilan quotidien enregistré !',

      // Weekly Questionnaire
      'weekly_title': 'Bilan Hebdomadaire',
      'take_front_photo': 'Prendre une photo de face',
      'photo_face': 'Photo Face',
      'photo_left': 'Profil Gauche',
      'photo_right': 'Profil Droit',
      'makeup_freq': 'Fréquence de maquillage',
      'makeup_type': 'Type de maquillage',
      'makeup_removal': 'Méthode de démaquillage',
      'cleansing_freq': 'Fréquence de nettoyage',
      'makeup_frequency_question': 'À quelle fréquence vous maquillez-vous ?',
      'makeup_type_question': 'Quel type de maquillage utilisez-vous ?',
      'makeup_removal_question': 'Comment vous démaquillez-vous ?',
      'cleansing_frequency_question': 'À quelle fréquence nettoyez-vous votre visage ?',
      'routine_followed_question': 'Avez-vous suivi votre routine cette semaine ?',
      'spf_usage_question': 'Avez-vous utilisé une protection solaire ?',
      'routine_followed': 'Routine suivie',
      'spf_this_week': 'Protection solaire cette semaine',
      'bilan_hebdo_saved': 'Bilan hebdomadaire enregistré !',
      'face_frontal': 'FACE FRONTALE',
      'cutaneous_audit': 'Audit Cutané',
      'audit_desc': 'Évaluons les progrès et l\'observance de ta routine.',
      'visual_analysis': 'Analyse Visuelle',
      'click_to_capture': 'Cliquez pour capturer',
      'makeup_cleansing': 'Maquillage & Nettoyage',
      'routine_observance': 'Observance Routine',
      'makeup_freq_label': 'FRÉQUENCE MAQUILLAGE',
      'makeup_type_label': 'TYPE DE MAQUILLAGE',
      'cleansing_label': 'DÉMAQUILLAGE',
      'cleansing_freq_label': 'FRÉQUENCE NETTOYAGE',
      'routine_followed_label': 'ROUTINE SUIVIE ?',
      'spf_label': 'PROTECTION SOLAIRE',
      'last_name': 'Nom',
      'confirm_password': 'Confirmer le mot de passe',
      'passwords_dont_match': 'Les mots de passe ne correspondent pas',

      // Profile Questionnaire
      'initial_title': 'Bilan Initial',
      'personal_profile': 'Profil Personnel',
      'skin_type_label': 'Type de Peau',
      'medical_bilan': 'Bilan Médical',
      'current_routine': 'Routine Actuelle',
      'menstrual_cycle_label': 'Cycle Menstruel',
      'first_name': 'Prénom',
      'pseudonym_forum': 'Pseudonyme (Forum)',
      'pcos_question': 'Avez-vous le SOPK ?',
      'acne_family': 'Antécédents familiaux d\'acné',
      'smoker_label': 'Fumeuse',
      'skin_type_question': 'Quel est ton type de peau ?',
      'cosmetic_allergies': 'Allergies cosmétiques connues',
      'acne_treatment_question': 'Traitement acné actuel',
      'hormonal_treatment_question': 'Contraception / Traitement hormonal',
      'last_period_date': 'DATE DES DERNIÈRES RÈGLES',
      'cycle_duration_3': 'DURÉE DES 3 DERNIERS CYCLES (JOURS)',
      'menstruation_duration_label': 'DURÉE MOYENNE DES RÈGLES (JOURS)',
      'day_label': 'Jour',
      'days_label': 'jours',
      'error_profile_info': 'Veuillez remplir toutes vos informations personnelles.',
      'loading_error': 'Erreur de chargement : ',
      'home_tab': 'Accueil',
      'routine_tab': 'Routine',
      'analysis_tab': 'Analyse',
      'profile_tab': 'Profil',
      'no_data': 'Aucune donnée',
      'recommendations_title': 'Recommandations',
      'lifestyle_tab': 'Vie',
      'hermona_journal': 'Journal Hermona',
      'analyses_tab': 'ANALYSES',
      'routines_tab': 'ROUTINES',
      'predictions_tab': 'PRÉDICTIONS',
      'chats_tab': 'CHATS',
      'no_analysis': 'Aucune analyse',
      'launch_scan_desc': 'Lancer un scan pour voir vos résultats.',
      'no_routine': 'Aucune routine',
      'personalized_routines_desc': 'Vos routines personnalisées apparaîtront ici.',
      'bespoke_routine': 'ROUTINE SUR-MESURE',
      'duration_label': 'Durée : ',
      'no_risk': 'Aucun risque',
      'anticipate_risks_desc': 'Anticipez les poussées avec l\'IA.',
      'no_chat': 'Aucun chat',
      'assistant_questions_desc': 'Vos questions à l\'assistante Hermona.',
      'analysis_results_title': 'Résultats de l\'analyse',
      'lesion_details': 'Détails des Lésions',
      'zone_analysis': 'Analyse par Zone',
      'view_recommendations': 'Voir mes recommandations',
      'severity_score': 'Score de sévérité',
      'detected_acne_types': 'Types d\'acné détectés',
      'risk_label': 'RISQUE',
      'status_label': 'ÉTAT',
      'healthy_skin': 'Peau Saine',
      'normal': 'Normal',
      'severity_low': 'Faible',
      'severity_moderate': 'Modérée',
      'severity_severe': 'Sévère',
      'severity_very_severe': 'Très Sévère',
      'severity_desc_low': 'Acné légère. Continuez votre routine de soins préventifs.',
      'severity_desc_moderate': 'Acné modérée. Une routine ciblée est recommandée.',
      'severity_desc_severe': 'Acné sévère. Consultez un dermatologue en complément des soins.',
      'severity_desc_very_severe': 'Acné très sévère. Une consultation dermatologique urgente est conseillée.',
      'front': 'FRONT',
      'chin': 'MENTON',
      'left_cheek': 'JOUE GAUCHE',
      'right_cheek': 'JOUE DROITE',
      'nose': 'NEZ',
      'visualization_unavailable': 'Visualisation indisponible',
      'viz_desc': 'Les photos détaillées par zone ne sont pas conservées pour optimiser la mémoire de l\'appareil.',
      'my_evolution': 'Mon Évolution',
      'skin_history': 'Historique de votre peau',
      'reports': 'bilans',
      'trackings': 'suivis',
      'cross_comparison': 'Comparaison Croisée',
      'correlation_risk_state': 'Corrélation entre votre risque et l\'état réel',
      'severity_weekly': 'Sévérité (Bilan Hebdo)',
      'evolution_photo_analysis': 'Évolution par analyse photo',
      'no_photo_analysis': 'Aucune analyse photo.',
      'risk_daily_tracking': 'Risque (Suivi Quotidien)',
      'evolution_responses': 'Évolution selon vos réponses',
      'no_daily_tracking': 'Aucun suivi quotidien.',
      'tap_point_details': 'Appuyez sur un point pour voir le détail et les photos historiques.',
      'tap_to_enlarge': 'Appuyez pour agrandir la photo',
      'weekly_report': 'Bilan Hebdo',
      'severity_score_label': 'SCORE DE SÉVÉRITÉ',
      'close': 'FERMER',
      'flare_risk': 'RISQUE DE POUSSÉE',
      'trend': 'Tendance',
      'assistant_hermona': 'Assistant Hermona',
      'chat_welcome': 'Bonjour ! Je suis Hermona AI ✨\n\nPosez-moi n\'importe quelle question sur votre peau ou votre cycle !\n\nVous pouvez aussi me parler avec le micro !',
      'chat_hint': 'Écrivez à Hermona...',
      'suggestion_1': 'Pourquoi mon risque est élevé aujourd\'hui ?',
      'suggestion_2': 'Quels produits éviter avec ma peau ?',
      'suggestion_3': 'Comment gérer l\'acné en phase lutéale ?',
      'suggestion_4': 'Quelle routine adopter cette semaine ?',
      'assistant_unavailable': 'Assistant indisponible',
      'listen': 'ÉCOUTER',
      'four_weeks': '4 semaines',
      'twelve_weeks': '12 semaines',
      'one_year': '1 an',
      'score_label': 'Score',
      'level_label': 'Niveau',
      'anon_messaging': 'Messagerie Anonyme',
      'anon_warning': 'Messagerie 100% anonyme. Ne partagez jamais vos données réelles.',
      'no_conversations': 'Aucune conversation',
      'start_chat_forum': 'Démarrez un chat depuis le forum.',
      'hermona_member': 'MEMBRE HERMONA',
      'delete': 'Supprimer',
      'hermona_member_title': 'Membre Hermona',
      'anon_online': 'Anonyme • En ligne',
      'personal_data_forbidden': 'Données personnelles interdites.',
      'say_hello': 'Dites bonjour !',
      'your_message_hint': 'Votre message...',
      'hermona_community': 'Communauté Hermona',
      'express_label': 'EXPRIMER',
      'search_subject_hint': 'Rechercher un sujet...',
      'recent_label': 'RÉCENT',
      'popular_label': 'POPULAIRE',
      'all_label': 'Tous',
      'no_results_found': 'Aucun résultat trouvé.',
      'secure_space': 'Espace Sécurisé',
      'safety_notice_desc': '🔒 Forum 100% anonyme.\n\n⚠️ Ne partagez JAMAIS :\n• Votre nom réel\n• Votre adresse\n• Votre téléphone\n\n🚨 Signalez tout contenu suspect.',
      'got_it': 'COMPRIS !',
      'direct_label': 'DIRECT',
      'delete_confirm_title': 'Supprimer ?',
      'cancel_caps': 'ANNULER',
      'yes_caps': 'OUI',
      'post_deleted': 'Post supprimé.',
      'report_content_title': 'Signaler ce contenu',
      'spam_label': 'Spam',
      'harassment_label': 'Harcèlement',
      'dangerous_medical_label': 'Contenu médical dangereux',
      'hateful_label': 'Haineux',
      'report_caps': 'SIGNALER',
      'report_thanks': 'Merci pour votre signalement.',
      'anonymous': 'Anonyme',
      'discussion_title': 'Discussion',
      'by_author_label': 'par',
      'replies_label': 'Réponses',
      'first_to_reply': 'Soyez la première à répondre ! 🧴',
      'replying_to': 'Répondre :',
      'your_reply_hint': 'Votre réponse...',
      'reply_button': 'Répondre',
      'new_post_title': 'Nouveau post',
      'anon_post_warning': 'Post anonyme. Ne partagez pas d\'infos personnelles.',
      'category_label': 'Catégorie',
      'title_with_asterisk': 'Titre *',
      'post_title_hint': 'Titre de votre question...',
      'min_5_chars': 'Min. 5 caractères',
      'content_with_asterisk': 'Contenu *',
      'post_content_hint': 'Décrivez votre question...',
      'min_20_chars': 'Min. 20 caractères',
      'publish_anon_label': 'Publier anonymement ✨',
      'error_prefix': 'Erreur',
      'welcome_title': 'Révèle l\'Éclat\nde ta Peau',
      'welcome_subtitle': 'Analyse faciale 5 zones, suivi du cycle, et routines expertes personnalisées.',
      'login_button': 'Se connecter',
      'create_account_button': 'Créer un compte',
      'reset_password_desc': 'Entrez votre adresse email pour recevoir un lien de réinitialisation.',
      'pseudonym_label': 'Pseudonyme (anonyme)',
      'terms_title_appbar': 'Conditions d\'utilisation',
      'terms_header': 'Hermona -- Conditions Générales',
      'terms_section_1_title': '1. Objet',
      'terms_section_1_content': 'Hermona est une application d\'aide à la détection d\'acné et de recommandation de soins. Elle ne remplace en aucun cas un avis médical professionnel.',
      'terms_section_2_title': '2. Données personnelles',
      'terms_section_2_content': 'Vos images sont collectées uniquement pour l\'analyse IA, stockées de manière sécurisée et ne sont jamais partagées avec des tiers sans votre consentement.',
      'terms_section_3_title': '3. Intelligence Artificielle',
      'terms_section_3_content': 'Les résultats fournis par l\'IA sont indicatifs. Pour tout problème dermatologique sérieux, consultez un médecin ou dermatologue.',
      'terms_section_4_title': '4. Forum anonyme',
      'terms_section_4_content': 'Le forum est anonyme. Vous êtes responsable des contenus publiés. Tout contenu inapproprié peut être signalé et supprimé.',
      'terms_section_5_title': '5. Messagerie privée',
      'terms_section_5_content': 'La messagerie est anonyme. Ne partagez jamais vos informations personnelles (nom, adresse, téléphone).',
      'terms_section_6_title': '6. Signalements',
      'terms_section_6_content': 'Tout contenu signalé 3 fois est automatiquement masqué en attente de modération.',
      'terms_section_7_title': '7. Modifications',
      'terms_section_7_content': 'Nous nous réservons le droit de modifier ces conditions à tout moment avec notification préalable.',
      'terms_medical_note': 'REMARQUE : Hermona ne fournit pas de diagnostics médicaux. Consultez toujours un professionnel de santé pour des problèmes dermatologiques.',
      'choose_language': 'Choisissez votre langue',
      'choose_language_sub': 'Choisissez votre langue préférée',
      'change_lang_sub': 'Changer la langue de l\'application',
      'french': 'Français',
      'english': 'English',
      'cycle_phase': 'Phase de Cycle',
      'morning_routine': 'Routine Matin',
      'evening_routine': 'Routine Soir',
      'avoid': 'À Éviter',
      'habits_hygiene': 'Habitudes & Hygiène',
      'follow_usual_routine': 'Continue ton hygiène habituelle.',
      'error_ia': 'Détection',
      'shap_stress': 'Stress',
      'shap_sleep': 'Sommeil',
      'shap_sleep_quality': 'Qualité Sommeil',
      'shap_hydration': 'Hydratation',
      'shap_diet': 'Alimentation',
      'shap_cycle_day': 'Jour du Cycle',
      'shap_cleansing': 'Nettoyage',
      'shap_spf_used': 'Protection SPF',
      'shap_makeup_frequency': 'Maquillage',
      'shap_routine_followed': 'Observance Routine',
      'phase_lutéale': 'Lutéale',
      'cat_general': 'Général',
      'cat_routine': 'Routine beauté',
      'cat_diet': 'Alimentation',
      'cat_hormones': 'Hormones',
      'cat_treatments': 'Traitements',
      'cat_stories': 'Témoignages',
      'cat_questions': 'Questions',
      'photo_tips_good': '✅ Lumière naturelle douce\n✅ Visage propre, sans maquillage\n✅ Photo nette, distance 20-30 cm\n✅ Fond neutre',
      'photo_tips_bad': '❌ Pas de filtres ni retouches\n❌ Pas de flash direct\n❌ Pas de lunettes\n❌ Éviter le mauvais éclairage',
      'welcome_footer': 'SCIENCE • ANONYME • SÉCURISÉ',
      'luteal_notif_body': 'Votre peau peut devenir plus grasse. N\'oubliez pas votre nettoyage soir !',
      'greeting_night': 'Bonne nuit',
      'greeting_morning': 'Bonjour',
      'greeting_afternoon': 'Bon après-midi',
      'greeting_evening': 'Bonsoir',
      'phase': 'Phase',
      'phase_menstrual_range': 'Jours 1-5',
      'phase_menstrual_desc': 'Hormones au plus bas.',
      'phase_follicular_range': 'Jours 6-13',
      'phase_follicular_desc': 'Peau plus éclatante.',
      'phase_ovulatory_range': 'Jours 14-15',
      'phase_ovulatory_desc': 'Pic hormonal.',
      'phase_luteal_range': 'Jours 16-28',
      'phase_luteal_desc': 'Pic de sébum.',
      'photo_unavailable': 'Photo non disponible',
      'acne_evolution': 'Évolution de l\'acné',
      'days': 'jours',

      'personal_info_sub': 'âge, IMC, etc.',

      'daily_q_done': 'Complété pour aujourd\'hui',

      'daily_q_todo': 'à remplir aujourd\'hui',

      'weekly_q_done': 'Déjà rempli cette semaine',

      'weekly_q_todo': 'Bilan de la semaine à faire',

      'logout_confirm_title': 'Déconnexion',

      'logout_confirm_desc': 'Voulez-vous vraiment vous déconnecter ?',




      'hello': 'Bonjour',

      'how_is_skin': 'Comment se sent ta peau aujourd\'hui ?',

      'risk': 'Risque',

      'latest_photo_analysis': 'Dernière Analyse Photo',


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


      'today_is': 'Aujourd\'hui est le',

      'assistant': 'Assistant',

      'messagerie': 'Messagerie',

      'phase_menstrual': '🌸 Phase Menstruelle',

      'phase_follicular': '🌿 Phase Folliculaire',

      'phase_ovulatory': '✨ Phase Ovulatoire',

      'phase_luteal': '🌙 Phase Lutéale',

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

      'register_welcome': 'Rejoignez notre communauté beauté 🌸',

      'required': 'Requis',

      'accept_terms': 'Veuillez accepter les conditions d\'utilisation',

      'i_accept': 'J\'accepte les ',

      'signup': 'S\'inscrire',

      'profile_hermona': 'Profil Hermona',

      'step': 'étape',

      'next': 'Suivant',


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

      'isotretinoin': 'Isotrétinoïne',

      'topical_cream': 'Crème topique',

      'current_hormonal_treatment': 'Traitement hormonal actuel',

      'pill': 'pilule',

      'implant': 'implant',

      'iud': 'Stérilet',

      'products_used': 'Quels produits utilises-tu ?',

      'morning': 'Le matin ☀️',

      'evening': 'Le soir 🌙',

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

      'daily_q_full_title': '📝 Questionnaire Quotidien',

      'stress_label': 'Stress (1-10)',

      'sleep_duration_label': 'Sommeil - Durée (heures)',

      'sleep_quality_label': 'Sommeil - Qualité (1-10)',

      'hydration_label': 'Hydratation (verres d\'eau)',

      'spf_today': 'SPF appliqué aujourd\'hui ?',

      'diet_label': 'Alimentation :',

      'symptoms_today': 'Symptômes du jour :',

      'already_done_today': '✅ Vous avez déjà rempli votre suivi pour aujourd\'hui.',

      'change_tap_edit': 'Si vous voulez changer, appuyez sur modifier en haut.',

      'update': 'Mettre à jour',

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

      'weekly_q_full_title': '📝 étape 3 : Bilan hebdomadaire',

      'face_photo_required': '📸 Photo de face requise',

      'face_photo_desc': 'Cette photo permet de suivre l\'évolution de votre acné chaque semaine.',

      'tap_to_take_photo': 'Cliquer pour prendre la photo',

      'makeup_label': '💄 Maquillage',

      'makeup_freq_week': 'Fréquence semaine',

      'makeup_removal_method': 'Démaquillage',

      'skincare_routine': '🧴 Routine de soin',

      'update_analyze': 'Mettre à jour & Analyser',

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

      'sometimes': 'Parfois',

      'prediction_hermona': 'Prédiction Hermona',

      'ready_for_report': 'Prête pour ton bilan ?',

      'prediction_desc': 'Notre IA va analyser ton cycle, ton hygiène de vie et tes données pour prédire les risques d\'imperfections.',

      'start_ia_analysis': 'Lancer l\'analyse IA',

      'analysis_hermona': 'Analyse Hermona',

      'avoid_tab': 'à éviter',

      'new_analysis': 'Nouvelle analyse',

      'risk_today': 'Risque aujourd\'hui',

      'prevention': 'PRéVENTION',

      'balance': 'éQUILIBRE',

      'protection': 'PROTECTION',

      'day_3': 'J+3',

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

      'acne_types_detected': 'Types d\'acné détectés',

      'severity_normal': 'Normal',

      'msg_normal': 'Votre peau semble saine. Continuez ainsi !',

      'msg_moderate': 'Pattern d\'acné modéré observé. Une routine de soin adaptée pourrait aider.',

      'msg_severe': 'Analyse montrant des signes importants. Nous recommandons de consulter un dermatologue.',

      'modify_weekly_report': 'Modifier mon bilan hebdomadaire',

      'error_first_name': 'Veuillez entrer votre prénom',

      'error_age': 'Veuillez entrer votre âge',

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

      'protection_glow': 'Protection & éclat',

      'repair_treatment': 'Réparation & Traitement',

      'recommended_brands': 'MARQUES CONSEILLéES',

      'inner_glow': 'Rayonner de l\'intérieur',

      'avoid_relapse': 'éviter les récidives',

      'error_load_rec': 'Impossible de charger vos recommandations. Vérifiez votre connexion au serveur.',

      'edit': 'Modifier',

      'my_history': 'Mon historique',

      'daily_tab': 'Quotidien',

      'weekly_tab': 'Hebdo',

      'analyze_skin_home': 'Analysez votre peau depuis l\'accueil',

      'analysis_id': 'Analyse #',

      'no_recommendation': 'Aucune recommandation',

      'analyze_skin_rec': 'Analysez votre peau pour obtenir des recommandations',

      'personalized_routine': 'Routine personnalisée',

      'duration': 'Durée',

      'no_prediction': 'Aucune prédiction',

      'anticipate_outbreaks': 'Utilisez la prédiction pour anticiper les poussées',

      'prediction_id': 'Prédiction #',

      'no_daily_survey': 'Aucun suivi quotidien',

      'fill_daily_survey': 'Remplissez votre suivi chaque jour',

      'no_weekly_survey': 'Aucun bilan hebdomadaire',

      'fill_weekly_survey': 'Faites votre bilan chaque semaine',

      'week_label': 'Semaine',

      'no_conversation': 'Aucune conversation',

      'ask_ia_assistant': 'Posez vos questions à l\'assistante IA',

      'posts': 'Posts',

      'terms_title': 'Conditions d\'utilisation',

      'terms_obj_title': '1. Objet',

      'terms_obj_desc': 'Hermona est une application d\'aide à la détection d\'acné et de recommandation de soins. Elle ne remplace en aucun cas un avis médical professionnel.',

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

      'terms_mod_desc': 'Nous nous réservons le droit de modifier ces conditions à tout moment avec notification préalable.',

      'terms_medical_disclaimer': '⚠️ Hermona ne fournit pas de diagnostics médicaux. Consultez toujours un professionnel de santé pour des problèmes dermatologiques.',

      'notification_center': 'Centre de Notifications',

      'notifications_connect': 'Connectez-vous pour voir vos notifications',

      'no_message': 'Aucun message',

      'no_alert': 'Aucune alerte',

      'message_desc': 'Vos messages privés apparaîtront ici.',

      'alert_desc': 'Vos alertes de risque et rappels apparaîtront ici.',

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

      'acne_evolution_sub': 'Score de sévérité (0-100)',

      'risk_evolution': 'Risque d\'Imperfections',

      'risk_evolution_sub': 'Probabilité prédite (%)',

      'trends_filter': 'Filtrer par période',

      'days_count': '{} jours',

      'expert_tip': 'Conseil d\'expert',

      'trends_tip_desc': 'Une courbe descendante indique une amélioration de l\'état de votre peau. Continuez votre routine Hermona !',

      'not_enough_data': 'Pas assez de données pour cette période.',
      'history_analysis': "Analyse d'historique",
      'view_full_analysis': "Voir l'analyse complète",
    },

    'en': {

      'welcome_title_long': 'Reveal Your Skin\'s Glow',

      'welcome_subtitle_long': 'AI-Powered Hormonal Acne Care',

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
      'continue': 'CONTINUE',
      'finish': 'FINISH BILAN',
      'cancel': 'Cancel',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'back': 'Back',
      'save': 'Save',
      'loading': 'Loading...',
      'error_occurred': 'An error occurred',
      'personal_info_required': 'Please fill all your personal information.',
      'customize_hermona': 'Customize Hermona',
      'apply': 'Apply',

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
      'personalization': 'Personalization',
      'dark_theme': 'Dark Theme',
      'enable_disable': 'On/Off',
      'brand_color': 'Brand Color',
      'stay': 'STAY',
      'leave': 'LEAVE',
      'analyses': 'Analyses',
      'risks': 'Risks',
      'mes_informations': 'My Information',
      'detection_results_sub': 'Detection results',
      'ai_history_sub': 'AI History',
      'assistant_messages_sub': 'Assistant messages',
      'age_label': 'Age',
      'score_ia': 'AI Score',
      'risk_high': 'High',
      'risk_medium': 'Medium',
      'risk_low': 'Low',
      'no_routine_available': 'No routine available',
      'start_analysis_btn': 'Start Analysis',
      'predictive_report_title': 'Predictive Report',
      'predictive_analysis': 'Predictive Analysis',
      'predictive_desc': 'Predict your future acne risks based on your cycle, hygiene, and habits.',
      'launch_ia_analysis': 'LAUNCH AI ANALYSIS',
      'ai_working_desc': 'AI is analyzing your data for a precise report...',
      'hermona_report': 'Hermona Report',
      'chat_private_title': 'Private Messaging',
      'analysis_tab_upper': 'ANALYSIS',
      'new_scan': 'NEW SCAN',
      'estimated_risk': 'Estimated Risk',
      'risk_j3_label': 'RISK J+3',
      'increasing': 'INCREASING',
      'stable': 'STABLE',
      'alerts_vigilance': 'Alerts & Vigilance',
      'alert_j3_title': 'Vigilance: J+3 Breakout',
      'alert_j3_desc': 'A risk increase is expected in 3 days. Prepare with your routine.',
      'alert_spf_title': 'Missing Sun Protection',
      'alert_spf_desc': 'Lack of SPF worsens inflammation and residual marks.',
      'alert_routine_title': 'Routine Compliance',
      'alert_routine_desc': 'Consistency is essential to stabilize your skin.',
      'alert_cleansing_title': 'Skin Cleansing',
      'alert_cleansing_desc': 'Infrequent cleansing promotes pore blockage by sebum.',
      'influence_factors': 'Influence Factors',
      'start_analyses_evolution': 'Start your analyses to see your evolution',
      'severity': 'Severity',
      'tap_for_details': 'Tap to see full details',
      'my_routine_title': 'MY ROUTINE',
      'ai_analysis': 'AI ANALYSIS',
      'hygiene': 'Hygiene',
      'pcos': 'PCOS',
      'hormonal_acne': 'Hormonal Acne',
      'cleansing_frequency': 'Cleansing Frequency',
      'diet': 'Diet',
      'stress': 'Stress',
      'sleep': 'Sleep',
      'hormonal_cycle': 'Hormonal Cycle',
      'pollution': 'Pollution',
      'uv': 'UV Exposure',
      'based_on_cycle_analysis': 'Based on your cycle analysis.',
      'top_factor_impact': 'Main factor: ',
      'routine_complete': 'Your routine is exemplary!',
      'good_habits_reinforce': 'Good habits, keep it up!',
      'improvement_points': 'Improvement points detected.',
      'morning_short': 'Morning',
      'evening_short': 'Evening',
      'lifestyle_short': 'Life',
      'step_label': 'Step',
      'strategy_protection': 'PROTECTION & REPAIR',
      'strategy_equilibrium': 'EQUILIBRIUM & PREVENTION',
      'strategy_prevention': 'ACTIVE PREVENTION',
      'adopted_strategy': 'ADOPTED STRATEGY',
      'alternative_label': 'Possible alternative: ',
      'low': 'Low',
      'option_yes': 'Yes',
      'option_no': 'No',
      'option_unknown': 'Unknown',
      'freq_never': 'Never',
      'freq_occasionally': 'Occasionally',
      'freq_daily': 'Daily',
      'makeup_light': 'Light',
      'makeup_medium': 'Medium',
      'makeup_full': 'Full coverage',
      'removal_micellar': 'Micellar water',
      'removal_oil': 'Oil/Balm',
      'removal_gel': 'Cleansing gel',
      'cleans_twice': 'Morning and evening',
      'cleans_once': 'Evening only',
      'routine_full': '100%',
      'routine_partial': 'Partially',
      'routine_rarely': 'Rarely',
      'spf_always': 'Every day',
      'spf_sometimes': 'Some days',
      'skin_grasse': 'Oily',
      'skin_mixte': 'Combination',
      'skin_seche': 'Dry',
      'skin_sensible': 'Sensitive',
      'skin_normale': 'Normal',
      'skin_acneique': 'Acne-prone',
      'allergy_none': 'None',
      'allergy_perfume': 'Perfumes',
      'allergy_preservatives': 'Preservatives',
      'allergy_alcohol': 'Cosmetic alcohol',
      'allergy_nickel': 'Nickel',
      'allergy_sunscreen': 'Sunscreen filters',
      'allergy_retinol': 'Retinol',
      'allergy_aha_bha': 'AHA-BHA',
      'hormonal_pill': 'Pill',
      'hormonal_implant': 'Implant',
      'hormonal_iud': 'IUD',
      'hormonal_none': 'None',
      'treat_antibiotics': 'Antibiotics',
      'treat_isotretinoin': 'Isotretinoin',
      'treat_topical': 'Topical cream',
      'treat_none': 'None',
      'prod_none': 'No product',
      'prod_cleanser': 'Gentle cleanser',
      'prod_tonic': 'Tonic',
      'prod_vit_c': 'Vitamin C serum',
      'prod_moisturizer': 'Moisturizer',
      'prod_spf': 'SPF',
      'prod_makeup_remover': 'Makeup remover',
      'prod_retinol': 'Active (Retinol)',
      'phase_menstrual_info': 'Menstrual Phase',
      'phase_follicular_info': 'Follicular Phase',
      'phase_ovulatory_info': 'Ovulatory Phase',
      'phase_luteal_info': 'Luteal Phase',
      'prod_hydrating_serum': 'Hydrating serum',
      'prod_night_cream': 'Night cream',

      // Why explanations (Rationale)
      'prod_makeup_remover_why': 'Oil attracts sebum and dissolves SPF effectively without irritating combination or oily skin.',
      'prod_cleanser_why': 'Gentle cleansing preserves the hydrolipid film while eliminating bacteria.',
      'prod_moisturizer_why': 'Well-hydrated skin regulates sebum production better and heals faster.',
      'prod_spf_why': 'The sun oxidizes sebum and fixes red/brown acne marks. It is your best anti-aging tool.',
      'prod_retinol_why': 'Retinol speeds up cell renewal to smooth skin texture and reduce blemishes.',
      'prod_hydrating_serum_why': 'Provides an intense dose of water to calm inflammation and plump the skin.',
      'why_this_choice': 'Why this choice?',

      // Daily Questionnaire
      'daily_title': 'Daily Bilan',
      'daily_header_title': 'Wellness Tracking',
      'daily_header_sub': 'Your data helps the AI refine its predictions.',
      'stress_level': 'Stress Level',
      'sleep_hours': 'Sleep Hours',
      'hydration_glasses': 'Hydration (Glasses)',
      'spf_protection': 'SPF Protection applied',
      'daily_diet': 'Daily Diet',
      'symptoms_felt': 'Symptoms felt',
      'analyze_day': 'ANALYZE MY DAY',
      'diet_balanced': 'balanced',
      'diet_sugar': 'sugar',
      'diet_dairy': 'dairy',
      'diet_fastfood': 'fast-food',
      'diet_fruits': 'fruits',
      'symptom_none': 'none',
      'symptom_cramps': 'cramps',
      'symptom_bloating': 'bloating',
      'symptom_mood': 'mood swings',
      'symptom_fatigue': 'fatigue',
      'symptom_breasts': 'tender breasts',
      'symptom_headache': 'headaches',
      'error_diet_required': 'Please select your diet for today.',
      'error_symptoms_required': 'Please select your symptoms (or "none").',
      'daily_saved': 'Daily bilan saved!',

      // Weekly Questionnaire
      'weekly_title': 'Weekly Bilan',
      'take_front_photo': 'Take a front photo',
      'photo_face': 'Face Photo',
      'photo_left': 'Left Profile',
      'photo_right': 'Right Profile',
      'makeup_freq': 'Makeup frequency',
      'makeup_type': 'Makeup type',
      'makeup_removal': 'Makeup removal method',
      'makeup_frequency_question': 'How often do you wear makeup?',
      'makeup_type_question': 'What type of makeup do you use?',
      'makeup_removal_question': 'How do you remove your makeup?',
      'cleansing_frequency_question': 'How often do you cleanse your face?',
      'routine_followed_question': 'Did you follow your routine this week?',
      'spf_usage_question': 'Did you use sun protection?',
      'routine_followed': 'Routine followed',
      'spf_this_week': 'Sunscreen usage this week',
      'bilan_hebdo_saved': 'Weekly bilan saved!',
      'cleansing_freq': 'Cleansing frequency',
      'current_routine': 'Current routine',
      'personal_profile': 'Personal profile',
      'once_day': '1x/day',

      // Profile Questionnaire
      'initial_title': 'Initial Bilan',
      'skin_type_label': 'Skin Type',
      'medical_bilan': 'Medical Bilan',
      'menstrual_cycle_label': 'Menstrual Cycle',
      'first_name': 'First Name',
      'pseudonym_forum': 'Pseudonym (Forum)',
      'pcos_question': 'Do you have PCOS?',
      'acne_family': 'Family history of acne',
      'smoker_label': 'Smoker',
      'skin_type_question': 'What is your skin type?',
      'cosmetic_allergies': 'Known cosmetic allergies',
      'acne_treatment_question': 'Current acne treatment',
      'hormonal_treatment_question': 'Contraception / Hormonal treatment',
      'last_period_date': 'LAST PERIOD DATE',
      'cycle_duration_3': 'DURATION OF LAST 3 CYCLES (DAYS)',
      'menstruation_duration_label': 'AVERAGE PERIOD DURATION (DAYS)',
      'day_label': 'Day',
      'days_label': 'days',
      'error_profile_info': 'Please fill all your personal information.',
      'loading_error': 'Loading error: ',
      'home_tab': 'Home',
      'routine_tab': 'Routine',
      'analysis_tab': 'Analysis',
      'profile_tab': 'Profile',
      'no_data': 'No data',
      'recommendations_title': 'Recommendations',
      'lifestyle_tab': 'Lifestyle',
      'hermona_journal': 'Hermona Journal',
      'analyses_tab': 'ANALYSES',
      'routines_tab': 'ROUTINES',
      'predictions_tab': 'PREDICTIONS',
      'chats_tab': 'CHATS',
      'no_analysis': 'No analysis',
      'launch_scan_desc': 'Launch a scan to see your results.',
      'no_routine': 'No routine',
      'personalized_routines_desc': 'Your personalized routines will appear here.',
      'bespoke_routine': 'BESPOKE ROUTINE',
      'duration_label': 'Duration: ',
      'no_risk': 'No risk',
      'anticipate_risks_desc': 'Anticipate flares with AI.',
      'no_chat': 'No chat',
      'assistant_questions_desc': 'Your questions to Assistant Hermona.',
      'analysis_results_title': 'Analysis Results',
      'lesion_details': 'Lesion Details',
      'zone_analysis': 'Zone Analysis',
      'view_recommendations': 'View My Recommendations',
      'severity_score': 'Severity Score',
      'detected_acne_types': 'Detected Acne Types',
      'risk_label': 'RISK',
      'status_label': 'STATUS',
      'healthy_skin': 'Healthy Skin',
      'normal': 'Normal',
      'severity_low': 'Low',
      'severity_moderate': 'Moderate',
      'severity_severe': 'Severe',
      'severity_very_severe': 'Very Severe',
      'severity_desc_low': 'Mild acne. Continue your preventive skincare routine.',
      'severity_desc_moderate': 'Moderate acne. A targeted routine is recommended.',
      'severity_desc_severe': 'Severe acne. Consult a dermatologist alongside skincare.',
      'severity_desc_very_severe': 'Very severe acne. Urgent dermatological consultation advised.',
      'front': 'FOREHEAD',
      'chin': 'CHIN',
      'left_cheek': 'LEFT CHEEK',
      'right_cheek': 'RIGHT CHEEK',
      'nose': 'NOSE',
      'visualization_unavailable': 'Visualization Unavailable',
      'viz_desc': 'Detailed zone photos are not stored to optimize device memory.',
      'my_evolution': 'My Evolution',
      'skin_history': 'Your Skin History',
      'reports': 'reports',
      'trackings': 'trackings',
      'cross_comparison': 'Cross Comparison',
      'correlation_risk_state': 'Correlation between risk and actual state',
      'severity_weekly': 'Severity (Weekly Report)',
      'evolution_photo_analysis': 'Evolution by photo analysis',
      'no_photo_analysis': 'No photo analysis.',
      'risk_daily_tracking': 'Risk (Daily Tracking)',
      'evolution_responses': 'Evolution based on responses',
      'no_daily_tracking': 'No daily tracking.',
      'tap_point_details': 'Tap a point to see details and history photos.',
      'tap_to_enlarge': 'Tap to enlarge photo',
      'weekly_report': 'Weekly Report',
      'severity_score_label': 'SEVERITY SCORE',
      'close': 'CLOSE',
      'flare_risk': 'FLARE RISK',
      'trend': 'Trend',
      'assistant_hermona': 'Hermona Assistant',
      'chat_welcome': 'Hello! I am Hermona AI ✨\n\nAsk me any question about your skin or cycle!\n\nYou can also talk to me using the mic!',
      'chat_hint': 'Write to Hermona...',
      'suggestion_1': 'Why is my risk high today?',
      'suggestion_2': 'Which products to avoid for my skin?',
      'suggestion_3': 'How to manage acne in luteal phase?',
      'suggestion_4': 'What routine to adopt this week?',
      'assistant_unavailable': 'Assistant unavailable',
      'listen': 'LISTEN',
      'four_weeks': '4 weeks',
      'twelve_weeks': '12 weeks',
      'one_year': '1 year',
      'score_label': 'Score',
      'level_label': 'Level',
      'anon_messaging': 'Anonymous Messaging',
      'anon_warning': '100% anonymous messaging. Never share your real data.',
      'no_conversations': 'No conversations',
      'start_chat_forum': 'Start a chat from the forum.',
      'hermona_member': 'HERMONA MEMBER',
      'delete': 'Delete',
      'hermona_member_title': 'Hermona Member',
      'anon_online': 'Anonymous • Online',
      'personal_data_forbidden': 'Personal data forbidden.',
      'say_hello': 'Say hello!',
      'your_message_hint': 'Your message...',
      'hermona_community': 'Hermona Community',
      'express_label': 'EXPRESS',
      'search_subject_hint': 'Search a subject...',
      'recent_label': 'RECENT',
      'popular_label': 'POPULAR',
      'all_label': 'All',
      'no_results_found': 'No results found.',
      'secure_space': 'Secure Space',
      'safety_notice_desc': '🔒 100% anonymous forum.\n\n⚠️ NEVER share:\n• Your real name\n• Your address\n• Your phone number\n\n🚨 Report any suspicious content.',
      'got_it': 'GOT IT!',
      'direct_label': 'DIRECT',
      'delete_confirm_title': 'Delete?',
      'cancel_caps': 'CANCEL',
      'yes_caps': 'YES',
      'post_deleted': 'Post deleted.',
      'report_content_title': 'Report this content',
      'spam_label': 'Spam',
      'harassment_label': 'Harassment',
      'dangerous_medical_label': 'Dangerous medical content',
      'hateful_label': 'Hateful',
      'report_caps': 'REPORT',
      'report_thanks': 'Thank you for your report.',
      'anonymous': 'Anonymous',
      'discussion_title': 'Discussion',
      'by_author_label': 'by',
      'replies_label': 'Replies',
      'first_to_reply': 'Be the first to reply! 🧴',
      'replying_to': 'Replying to:',
      'your_reply_hint': 'Your reply...',
      'reply_button': 'Reply',
      'new_post_title': 'New Post',
      'anon_post_warning': 'Anonymous post. Do not share personal info.',
      'category_label': 'Category',
      'title_with_asterisk': 'Title *',
      'post_title_hint': 'Title of your question...',
      'min_5_chars': 'Min. 5 characters',
      'content_with_asterisk': 'Content *',
      'post_content_hint': 'Describe your question...',
      'min_20_chars': 'Min. 20 characters',
      'publish_anon_label': 'Publish anonymously ✨',
      'error_prefix': 'Error',
      'welcome_title': 'Reveal Your\nSkin\'s Glow',
      'welcome_subtitle': '5-zone facial analysis, cycle tracking, and personalized expert routines.',
      'login_button': 'Log In',
      'create_account_button': 'Create Account',
      'reset_password_desc': 'Enter your email address to receive a reset link.',
      'pseudonym_label': 'Pseudonym (anonymous)',
      'terms_title_appbar': 'Terms of Use',
      'terms_header': 'Hermona -- General Terms',
      'terms_section_1_title': '1. Purpose',
      'terms_section_1_content': 'Hermona is an application to help with acne detection and skincare recommendations. It is not a substitute for professional medical advice.',
      'terms_section_2_title': '2. Personal Data',
      'terms_section_2_content': 'Your images are collected solely for AI analysis, stored securely, and are never shared with third parties without your consent.',
      'terms_section_3_title': '3. Artificial Intelligence',
      'terms_section_3_content': 'The results provided by the AI are indicative. For any serious dermatological problem, consult a doctor or dermatologist.',
      'terms_section_4_title': '4. Anonymous Forum',
      'terms_section_4_content': 'The forum is anonymous. You are responsible for the content published. Any inappropriate content can be reported and deleted.',
      'terms_section_5_title': '5. Private Messaging',
      'terms_section_5_content': 'Messaging is anonymous. Never share your personal information (name, address, phone).',
      'terms_section_6_title': '6. Reports',
      'terms_section_6_content': 'Any content reported 3 times is automatically hidden pending moderation.',
      'terms_section_7_title': '7. Modifications',
      'terms_section_7_content': 'We reserve the right to modify these terms at any time with prior notice.',
      'terms_medical_note': 'NOTE: Hermona does not provide medical diagnoses. Always consult a health professional for dermatological problems.',
      'choose_language': 'Choose your language',
      'choose_language_sub': 'Choose your preferred language',
      'change_lang_sub': 'Change the application language',
      'french': 'French',
      'english': 'English',
      'cycle_phase': 'Cycle Phase',
      'morning_routine': 'Morning Routine',
      'evening_routine': 'Evening Routine',
      'avoid': 'To Avoid',
      'habits_hygiene': 'Habits & Hygiene',
      'follow_usual_routine': 'Continue your usual hygiene.',
      'error_ia': 'Detection',
      'shap_stress': 'Stress',
      'shap_sleep': 'Sleep',
      'shap_sleep_quality': 'Sleep Quality',
      'shap_hydration': 'Hydration',
      'shap_diet': 'Diet',
      'shap_cycle_day': 'Cycle Day',
      'shap_cleansing': 'Cleansing',
      'shap_spf_used': 'SPF Protection',
      'shap_makeup_frequency': 'Makeup',
      'shap_routine_followed': 'Routine Compliance',
      'phase_lutéale': 'Luteal',
      'cat_general': 'General',
      'cat_routine': 'Beauty Routine',
      'cat_diet': 'Diet',
      'cat_hormones': 'Hormones',
      'cat_treatments': 'Treatments',
      'cat_stories': 'Stories',
      'cat_questions': 'Questions',
      'photo_tips_good': '✅ Soft natural light\n✅ Clean face, no makeup\n✅ Clear photo, 20-30 cm distance\n✅ Neutral background',
      'photo_tips_bad': '❌ No filters or editing\n❌ No direct flash\n❌ No glasses\n❌ Avoid poor lighting',
      'welcome_footer': 'SCIENCE-DRIVEN • ANONYMOUS • SECURE',
      'high': 'High',
      'medium': 'Medium',
      'greeting_night': 'Good night',
      'greeting_morning': 'Good morning',
      'greeting_afternoon': 'Good afternoon',
      'greeting_evening': 'Good evening',
      'phase': 'Phase',
      'phase_menstrual_range': 'Days 1-5',
      'phase_menstrual_desc': 'Hormones at lowest.',
      'phase_follicular_range': 'Days 6-13',
      'phase_follicular_desc': 'Skin more radiant.',
      'phase_ovulatory_range': 'Days 14-15',
      'phase_ovulatory_desc': 'Hormonal peak.',
      'phase_luteal_range': 'Days 16-28',
      'phase_luteal_desc': 'Sebum peak.',
      'photo_unavailable': 'Photo unavailable',
      'acne_evolution': 'Acne Evolution',
      'days': 'days',
      'personal_info_sub': 'Age, BMI, etc.',
      'daily_q_done': 'Completed for today',
      'daily_q_todo': 'To fill out today',
      'weekly_q_done': 'Already filled this week',
      'weekly_q_todo': 'Weekly review to do',
      'logout_confirm_title': 'Logout',
      'logout_confirm_desc': 'Do you really want to log out?',
      'hello': 'Hello',
      'how_is_skin': 'How is your skin feeling today?',
      'risk': 'Risk',
      'latest_photo_analysis': 'Latest Photo Analysis',
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
      'today_is': 'Today is the',
      'assistant': 'Assistant',
      'messagerie': 'Messaging',
      'phase_menstrual': '🌸 Menstrual Phase',
      'phase_follicular': '🌿 Follicular Phase',
      'phase_ovulatory': '✨ Ovulatory Phase',
      'phase_luteal': '🌙 Luteal Phase',
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
      'register_welcome': 'Join our beauty community 🌸',
      'required': 'Required',
      'accept_terms': 'Please accept the terms of use',
      'i_accept': 'I accept the ',
      'signup': 'Sign Up',
      'last_name': 'Last Name',
      'confirm_password': 'Confirm Password',
      'passwords_dont_match': 'Passwords do not match',
      'profile_hermona': 'Hermona Profile',
      'step': 'Step',
      'next': 'Next',
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
      'products_used': 'Which products do you use?',
      'morning': 'Morning ☀️',
      'evening': 'Evening 🌙',
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
      'daily_q_full_title': '📝 Daily Questionnaire',
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
      'weekly_q_full_title': '📝 Step 3: Weekly Review',
      'face_photo_required': '📸 Face photo required',
      'face_photo_desc': 'This photo allows tracking the evolution of your acne every week.',
      'tap_to_take_photo': 'Tap to take photo',
      'makeup_label': '💄 Makeup',
      'makeup_freq_week': 'Frequency per week',
      'makeup_removal_method': 'Makeup removal',
      'skincare_routine': '🧴 Skincare routine',

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

      'face_frontal': 'FRONTAL FACE',
      'cutaneous_audit': 'Skin Audit',
      'audit_desc': 'Let\'s evaluate the progress and compliance of your routine.',
      'visual_analysis': 'Visual Analysis',
      'click_to_capture': 'Click to capture',
      'makeup_cleansing': 'Makeup & Cleansing',
      'routine_observance': 'Routine Compliance',
      'makeup_freq_label': 'MAKEUP FREQUENCY',
      'makeup_type_label': 'MAKEUP TYPE',
      'cleansing_label': 'CLEANSING',
      'cleansing_freq_label': 'CLEANSING FREQUENCY',
      'routine_followed_label': 'ROUTINE FOLLOWED?',
      'spf_label': 'SUN PROTECTION',

      'sometimes': 'Sometimes',

      'prediction_hermona': 'Hermona Prediction',

      'ready_for_report': 'Ready for your report?',

      'prediction_desc': 'Our AI will analyze your cycle, lifestyle and data to predict the risks of imperfections.',

      'start_ia_analysis': 'Start AI analysis',

      'analysis_hermona': 'Hermona Analysis',

      'avoid_tab': 'To avoid',

      'new_analysis': 'New analysis',

      'risk_today': 'Risk today',

      'prevention': 'PREVENTION',

      'balance': 'BALANCE',

      'protection': 'PROTECTION',

      'day_3': 'D+3',

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

      'acne_types_detected': 'Acne types detected',

      'severity_normal': 'Normal',

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

      'protection_glow': 'Protection & Glow',

      'repair_treatment': 'Repair & Treatment',

      'recommended_brands': 'RECOMMENDED BRANDS',

      'inner_glow': 'Inner Glow',

      'avoid_relapse': 'Avoid Relapse',

      'error_load_rec': 'Unable to load your recommendations. Check your server connection.',

      'edit': 'Edit',

      'my_history': 'My History',

      'daily_tab': 'Daily',

      'weekly_tab': 'Weekly',

      'analyze_skin_home': 'Analyze your skin from the home screen',

      'analysis_id': 'Analysis #',

      'no_recommendation': 'No recommendation',

      'analyze_skin_rec': 'Analyze your skin to get recommendations',

      'personalized_routine': 'Personalized routine',

      'duration': 'Duration',

      'no_prediction': 'No prediction',

      'anticipate_outbreaks': 'Use prediction to anticipate outbreaks',

      'prediction_id': 'Prediction #',

      'no_daily_survey': 'No daily survey',

      'fill_daily_survey': 'Fill out your tracking every day',

      'no_weekly_survey': 'No weekly review',

      'fill_weekly_survey': 'Do your review every week',

      'week_label': 'Week',

      'no_conversation': 'No conversation',

      'ask_ia_assistant': 'Ask your questions to the AI assistant',

      'posts': 'Posts',

      'terms_title': 'Terms of Use',

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

      'terms_medical_disclaimer': '⚠️ Hermona does not provide medical diagnoses. Always consult a healthcare professional for dermatological problems.',

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

      'acne_evolution_sub': 'Severity score (0-100)',

      'risk_evolution': 'Blemish Risk',

      'risk_evolution_sub': 'Predicted probability (%)',

      'trends_filter': 'Filter by period',

      'days_count': '{} days',

      'expert_tip': 'Expert Tip',

      'trends_tip_desc': 'A downward curve indicates an improvement in your skin condition. Keep up your Hermona routine!',

      'not_enough_data': 'Not enough data for this period.',
      'history_analysis': "History Analysis",
      'view_full_analysis': "View full analysis",
    },
  };

  String translate(String key) {
    final value = _localizedValues[locale.languageCode]?[key] ?? key;
    debugPrint("DEBUG AUDIT: translate($key) in ${locale.languageCode} -> $value");
    return value;
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
