import re

file_path = r'c:\Users\asus\hermona1\lib\core\localization\app_localizations.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_keys = {
    'incomplete_surveys_title': ('Questionnaires Incomplets', 'Incomplete Surveys'),
    'incomplete_surveys_desc': ('Veuillez remplir vos questionnaires pour faire un nouveau scan.', 'Please fill out your surveys to perform a new scan.'),
    'daily_bilan_btn': ('Bilan Quotidien', 'Daily Survey'),
    'weekly_bilan_btn': ('Bilan Hebdomadaire', 'Weekly Survey'),
    'weekly_saved_no_photo': ('Bilan hebdomadaire enregistré. Analyse photo indisponible pour le moment.', 'Weekly survey saved. Photo analysis currently unavailable.'),
    'soin_cible': ('Soin cible', 'Targeted care'),
    'traitement': ('Traitement', 'Treatment'),
    'all_skin_types': ('Tous types de peau', 'All skin types'),
    'apply_small_amount': ('Appliquer une noisette sur le visage', 'Apply a small amount to the face'),
    'recommended_2_star': ('Recommandé ⭐⭐', 'Recommended ⭐⭐'),
    'medium_budget': ('Budget moyen', 'Medium budget'),
    'cleanser_purifying': ('Nettoyant Purifiant (Cleanser)', 'Purifying Cleanser'),
    'sebum_control_cleaning': ('Contrôle du sébum et nettoyage en profondeur', 'Sebum control and deep cleansing'),
    'oily_mixed_acne': ('Peau grasse, mixte, acnéique', 'Oily, combination, acne-prone skin'),
    'lather_wet_face': ('Faire mousser sur visage humide, masser 60s, puis rincer.', 'Lather on wet face, massage for 60s, then rinse.'),
    'essential_3_star': ('Essentiel ⭐⭐⭐', 'Essential ⭐⭐⭐'),
    'cleanser_gentle': ('Nettoyant Doux (Cleanser)', 'Gentle Cleanser'),
    'respectful_cleaning': ('Nettoyage respectueux de la barrière cutanée', 'Gentle cleansing that respects the skin barrier'),
    'sensitive_dry_fragile': ('Peau sensible, sèche, fragilisée', 'Sensitive, dry, fragile skin'),
    'massage_gently_wet_face': ("Masser doucement sur visage humide, rincer à l'eau tiède.", "Gently massage onto wet face, rinse with lukewarm water."),
    'serum_antioxidant': ('Sérum (Antioxydant)', 'Serum (Antioxidant)'),
    'radiance_protection': ('Éclat du teint et protection contre les radicaux libres', 'Complexion radiance and protection against free radicals'),
    'all_skin_types_except_sensitive': ('Tous types de peau (sauf très sensible)', 'All skin types (except very sensitive)'),
    'apply_morning_before_moisturizer': ('Appliquer le matin avant la crème hydratante et le SPF.', 'Apply in the morning before moisturizer and SPF.'),
    'optional_1_star': ('Optionnel ⭐', 'Optional ⭐'),
    'high_budget': ('Budget élevé', 'High budget'),
    'serum_regulator': ('Sérum (Régulateur)', 'Serum (Regulator)'),
    'pore_reduction_sebum_control': ('Réduction des pores, contrôle du sébum et anti-rougeurs', 'Pore reduction, sebum control, and anti-redness'),
    'mixed_oily_blemish': ('Peau mixte, grasse, à imperfections', 'Combination, oily, blemish-prone skin'),
    'apply_morning_evening_before_moisturizer': ('Appliquer matin et/ou soir avant la crème hydratante.', 'Apply morning and/or evening before moisturizer.'),
    'low_budget': ('Budget faible', 'Low budget'),
    'serum_renewal': ('Sérum (Renouvellement)', 'Serum (Renewal)'),
    'anti_aging_anti_marks': ('Anti-âge, anti-marques, accélération du renouvellement cellulaire', 'Anti-aging, anti-marks, accelerated cell renewal'),
    'mature_residual_marks': ('Peau mature, peau à marques résiduelles', 'Mature skin, skin with residual marks'),
    'apply_evening_only_retinol': ('Appliquer uniquement le soir. Commencer 2x/semaine. SPF obligatoire le lendemain.', 'Apply only in the evening. Start 2x/week. SPF mandatory the next day.'),
    'chemical_exfoliant': ('Exfoliant Chimique (Sérum/Lotion)', 'Chemical Exfoliant (Serum/Lotion)'),
    'pore_unclogging_anti_blackheads': ('Désobstruction des pores, anti-points noirs, anti-inflammatoire', 'Pore unclogging, anti-blackheads, anti-inflammatory'),
    'oily_blackheads': ('Peau grasse, sujette aux points noirs', 'Oily skin, prone to blackheads'),
    'apply_2_3_times_evening': ('Appliquer 2 à 3 fois par semaine le soir. Ne pas mélanger avec le rétinol.', 'Apply 2 to 3 times a week in the evening. Do not mix with retinol.'),
    'day_cream': ('Crème de jour (Moisturizer)', 'Day cream (Moisturizer)'),
    'light_hydration_shine_control': ('Hydratation légère et contrôle de la brillance', 'Light hydration and shine control'),
    'oily_mixed': ('Peau grasse, peau mixte', 'Oily skin, combination skin'),
    'apply_morning_evening_clean_face': ('Appliquer matin et soir sur le visage propre.', 'Apply morning and evening on clean face.'),
    'rich_cream': ('Crème riche (Moisturizer)', 'Rich cream (Moisturizer)'),
    'intense_hydration_barrier_repair': ('Hydratation intense et réparation barrière cutanée', 'Intense hydration and skin barrier repair'),
    'dry_very_dry_drying_treatment': ('Peau sèche, très sèche, sous traitement asséchant', 'Dry, very dry skin, under drying treatment'),
    'apply_generously_morning_evening': ('Appliquer généreusement matin et soir.', 'Apply generously morning and evening.'),
    'sunscreen': ('Protection Solaire (Sunscreen)', 'Sun Protection (Sunscreen)'),
    'uv_protection_hyperpigmentation': ('Protection UV, prévention des marques hyperpigmentées', 'UV protection, prevention of hyperpigmentation marks'),
    'apply_2_fingers_morning': ("Appliquer 2 doigts de produit le matin en fin de routine. Renouveler en cas d'exposition directe.", "Apply 2 fingers of product in the morning at the end of the routine. Reapply in case of direct exposure."),
    'cleansing_balm': ('Baume Démaquillant (Cleanser)', 'Cleansing Balm (Cleanser)'),
    'effective_makeup_removal_sebum_spf': ('Démaquillage efficace, élimination du sébum et du SPF', 'Effective makeup removal, elimination of sebum and SPF'),
    'all_skin_types_double_cleansing': ('Tous types de peau (Double nettoyage)', 'All skin types (Double cleansing)'),
    'massage_dry_skin_emulsify': ("Masser sur peau sèche pour dissoudre le maquillage, émulsionner à l'eau puis rincer.", "Massage on dry skin to dissolve makeup, emulsify with water then rinse."),
    'repairing_balm': ('Baume Réparateur (Moisturizer)', 'Repairing Balm (Moisturizer)'),
    'healing_intense_soothing': ('Cicatrisation, apaisement intense, réparation barrière cutanée', 'Healing, intense soothing, skin barrier repair'),
    'irritated_fragile_post_treatment': ('Peau irritée, peau fragilisée (Post-traitement)', 'Irritated skin, fragile skin (Post-treatment)'),
    'apply_thick_layer_irritated_areas': ('Appliquer en couche épaisse sur les zones irritées le soir.', 'Apply a thick layer on irritated areas in the evening.'),
}

def escape_str(s):
    return s.replace("'", "\\'")

fr_adds = '\n'.join([f"      '{k}': '{escape_str(v[0])}'," for k, v in new_keys.items()])
en_adds = '\n'.join([f"      '{k}': '{escape_str(v[1])}'," for k, v in new_keys.items()])

content = re.sub(r"('fr':\s*\{)", r"\1\n" + fr_adds + "\n", content)
content = re.sub(r"('en':\s*\{)", r"\1\n" + en_adds + "\n", content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Updated app_localizations.dart')
