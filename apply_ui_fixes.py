import os

# 1. prediction_screen.dart
ps_path = r'c:\Users\asus\hermona1\lib\features\prediction\presentation\screens\prediction_screen.dart'
with open(ps_path, 'r', encoding='utf-8') as f:
    ps_content = f.read()

ps_content = ps_content.replace('"Questionnaires Incomplets"', 'l.translate(\'incomplete_surveys_title\')')
ps_content = ps_content.replace('"Veuillez remplir vos questionnaires pour faire un nouveau scan."', 'l.translate(\'incomplete_surveys_desc\')')
ps_content = ps_content.replace('"Bilan Quotidien"', 'l.translate(\'daily_bilan_btn\')')
ps_content = ps_content.replace('"Bilan Hebdomadaire"', 'l.translate(\'weekly_bilan_btn\')')

with open(ps_path, 'w', encoding='utf-8') as f:
    f.write(ps_content)


# 2. weekly_questionnaire_screen.dart
wq_path = r'c:\Users\asus\hermona1\lib\features\questionnaire\presentation\screens\weekly_questionnaire_screen.dart'
with open(wq_path, 'r', encoding='utf-8') as f:
    wq_content = f.read()

# We need `l.translate()` here. The context should be available. Let's just use `AppLocalizations.of(context).translate(...)`
wq_content = wq_content.replace("'Bilan hebdomadaire enregistré. Analyse photo indisponible pour le moment.'", "AppLocalizations.of(context).translate('weekly_saved_no_photo')")

with open(wq_path, 'w', encoding='utf-8') as f:
    f.write(wq_content)


# 3. my_routine_screen.dart
mr_path = r'c:\Users\asus\hermona1\lib\features\recommendation\presentation\screens\my_routine_screen.dart'
with open(mr_path, 'r', encoding='utf-8') as f:
    mr_content = f.read()

# Modify _getProductMetadata to accept AppLocalizations l
mr_content = mr_content.replace('Map<String, dynamic> _getProductMetadata(String name) {', 'Map<String, dynamic> _getProductMetadata(String name, AppLocalizations l) {')
mr_content = mr_content.replace('final meta = _getProductMetadata(productName);', 'final meta = _getProductMetadata(productName, l);')

# Wait, `l` needs to be defined in `_showSpecificProductDetails`.
# It's currently: void _showSpecificProductDetails(BuildContext context, String productName, String imageUrl)
# Let's just pass `AppLocalizations.of(context)` directly:
# We will use re.sub or just simple replace for the translations.
# It's safer to use AppLocalizations.of(context).translate() in _getProductMetadata if we just pass context.
# Let's change `_getProductMetadata` to accept `BuildContext context` instead.
mr_content = mr_content.replace('Map<String, dynamic> _getProductMetadata(String name, AppLocalizations l) {', 'Map<String, dynamic> _getProductMetadata(String name, BuildContext context) {')
mr_content = mr_content.replace('Map<String, dynamic> _getProductMetadata(String name) {', 'Map<String, dynamic> _getProductMetadata(String name, BuildContext context) {')
mr_content = mr_content.replace('final meta = _getProductMetadata(productName);', 'final meta = _getProductMetadata(productName, context);')
mr_content = mr_content.replace('final meta = _getProductMetadata(productName, l);', 'final meta = _getProductMetadata(productName, context);')

# Now insert `final l = AppLocalizations.of(context);` at the top of _getProductMetadata
mr_content = mr_content.replace('''Map<String, dynamic> _getProductMetadata(String name, BuildContext context) {
    final lName = name.toLowerCase();''', '''Map<String, dynamic> _getProductMetadata(String name, BuildContext context) {
    final l = AppLocalizations.of(context);
    final lName = name.toLowerCase();''')

# Now replace all the hardcoded strings
replacements = {
    "'Soin cible'": "l.translate('soin_cible')",
    "'Traitement'": "l.translate('traitement')",
    "'Tous types de peau'": "l.translate('all_skin_types')",
    "'Appliquer une noisette sur le visage'": "l.translate('apply_small_amount')",
    "'Recommandé ⭐⭐'": "l.translate('recommended_2_star')",
    "'Budget moyen'": "l.translate('medium_budget')",
    "'Nettoyant Purifiant (Cleanser)'": "l.translate('cleanser_purifying')",
    "'Contrôle du sébum et nettoyage en profondeur'": "l.translate('sebum_control_cleaning')",
    "'Peau grasse, mixte, acnéique'": "l.translate('oily_mixed_acne')",
    "'Faire mousser sur visage humide, masser 60s, puis rincer.'": "l.translate('lather_wet_face')",
    "'Essentiel ⭐⭐⭐'": "l.translate('essential_3_star')",
    "'Nettoyant Doux (Cleanser)'": "l.translate('cleanser_gentle')",
    "'Nettoyage respectueux de la barrière cutanée'": "l.translate('respectful_cleaning')",
    "'Peau sensible, sèche, fragilisée'": "l.translate('sensitive_dry_fragile')",
    "'Masser doucement sur visage humide, rincer à l\\'eau tiède.'": "l.translate('massage_gently_wet_face')",
    "'Sérum (Antioxydant)'": "l.translate('serum_antioxidant')",
    "'Éclat du teint et protection contre les radicaux libres'": "l.translate('radiance_protection')",
    "'Tous types de peau (sauf très sensible)'": "l.translate('all_skin_types_except_sensitive')",
    "'Appliquer le matin avant la crème hydratante et le SPF.'": "l.translate('apply_morning_before_moisturizer')",
    "'Optionnel ⭐'": "l.translate('optional_1_star')",
    "'Budget élevé'": "l.translate('high_budget')",
    "'Sérum (Régulateur)'": "l.translate('serum_regulator')",
    "'Réduction des pores, contrôle du sébum et anti-rougeurs'": "l.translate('pore_reduction_sebum_control')",
    "'Peau mixte, grasse, à imperfections'": "l.translate('mixed_oily_blemish')",
    "'Appliquer matin et/ou soir avant la crème hydratante.'": "l.translate('apply_morning_evening_before_moisturizer')",
    "'Budget faible'": "l.translate('low_budget')",
    "'Sérum (Renouvellement)'": "l.translate('serum_renewal')",
    "'Anti-âge, anti-marques, accélération du renouvellement cellulaire'": "l.translate('anti_aging_anti_marks')",
    "'Peau mature, peau à marques résiduelles'": "l.translate('mature_residual_marks')",
    "'Appliquer uniquement le soir. Commencer 2x/semaine. SPF obligatoire le lendemain.'": "l.translate('apply_evening_only_retinol')",
    "'Exfoliant Chimique (Sérum/Lotion)'": "l.translate('chemical_exfoliant')",
    "'Désobstruction des pores, anti-points noirs, anti-inflammatoire'": "l.translate('pore_unclogging_anti_blackheads')",
    "'Peau grasse, sujette aux points noirs'": "l.translate('oily_blackheads')",
    "'Appliquer 2 à 3 fois par semaine le soir. Ne pas mélanger avec le rétinol.'": "l.translate('apply_2_3_times_evening')",
    "'Crème de jour (Moisturizer)'": "l.translate('day_cream')",
    "'Hydratation légère et contrôle de la brillance'": "l.translate('light_hydration_shine_control')",
    "'Peau grasse, peau mixte'": "l.translate('oily_mixed')",
    "'Appliquer matin et soir sur le visage propre.'": "l.translate('apply_morning_evening_clean_face')",
    "'Crème riche (Moisturizer)'": "l.translate('rich_cream')",
    "'Hydratation intense et réparation barrière cutanée'": "l.translate('intense_hydration_barrier_repair')",
    "'Peau sèche, très sèche, sous traitement asséchant'": "l.translate('dry_very_dry_drying_treatment')",
    "'Appliquer généreusement matin et soir.'": "l.translate('apply_generously_morning_evening')",
    "'Protection Solaire (Sunscreen)'": "l.translate('sunscreen')",
    "'Protection UV, prévention des marques hyperpigmentées'": "l.translate('uv_protection_hyperpigmentation')",
    "'Appliquer 2 doigts de produit le matin en fin de routine. Renouveler en cas d\\'exposition directe.'": "l.translate('apply_2_fingers_morning')",
    "'Baume Démaquillant (Cleanser)'": "l.translate('cleansing_balm')",
    "'Démaquillage efficace, élimination du sébum et du SPF'": "l.translate('effective_makeup_removal_sebum_spf')",
    "'Tous types de peau (Double nettoyage)'": "l.translate('all_skin_types_double_cleansing')",
    "'Masser sur peau sèche pour dissoudre le maquillage, émulsionner à l\\'eau puis rincer.'": "l.translate('massage_dry_skin_emulsify')",
    "'Baume Réparateur (Moisturizer)'": "l.translate('repairing_balm')",
    "'Cicatrisation, apaisement intense, réparation barrière cutanée'": "l.translate('healing_intense_soothing')",
    "'Peau irritée, peau fragilisée (Post-traitement)'": "l.translate('irritated_fragile_post_treatment')",
    "'Appliquer en couche épaisse sur les zones irritées le soir.'": "l.translate('apply_thick_layer_irritated_areas')",
}

for old, new in replacements.items():
    mr_content = mr_content.replace(old, new)

with open(mr_path, 'w', encoding='utf-8') as f:
    f.write(mr_content)
print('Applied UI replacements')
