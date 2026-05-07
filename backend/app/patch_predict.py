# -*- coding: utf-8 -*-
"""
Patch the /predict endpoint in main.py to fix the stuck-at-52% bug.
Run once from the backend/app/ directory: python patch_predict.py
"""

with open('main.py', 'r', encoding='utf-8') as f:
    content = f.read()

new_body = '''    answers = body.answers

    # Valeurs par defaut (moyennes) pour les 40 features du modele
    data = {
        'age': 25, 'pcos': 0, 'stress': 5, 'sommeil': 7, 'alimentation_impact': 0.5,
        'LH': 5.0, 'estradiol': 50.0, 'progesterone': 10.0, 'testosterone': 0.5,
        'jour_cycle': 14, 'soleil_heures': 1.0, 'protection_solaire': 1,
        'allergies': 0, 'antecedents_familiaux': 0, 'maquillage': 1,
        'hydratation_verres': 6, 'fumeur': 0, 'cigarettes': 0, 'imc': 22.0,
        'alcool_jamais': 1, 'alcool_occasionnel': 0, 'alcool_régulier': 0,
        'type_peau_acnéique': 0, 'type_peau_déshydratée': 0,
        'type_peau_grasse': 0, 'type_peau_mixte': 1, 'type_peau_normale': 0,
        'type_peau_seche': 0, 'type_peau_sensible': 0,
        'sport_1-2x/semaine': 1, 'sport_3-4x/semaine': 0, 'sport_jamais': 0,
        'lavage_1x/jour': 0, 'lavage_2x/jour': 1, 'lavage_3x/jour': 0, 'lavage_parfois': 0,
        'phase_folliculaire': 1, 'phase_luteale': 0, 'phase_menstruelle': 0, 'phase_ovulatoire': 0
    }

    factors = []

    # ── ETAPE 1 : Injection du PROFIL UTILISATEUR depuis Firestore ──────────────
    # Le profil est imbrique dans answers['profile'] (envoye par prediction_api_service.dart)
    profile = answers.get('profile', {})
    skin_raw = 'mixte'  # valeur par defaut pour le logger

    if profile:
        # Age
        age = profile.get('age')
        if isinstance(age, (int, float)) and age > 0:
            data['age'] = int(age)

        # IMC
        imc = profile.get('imc')
        if isinstance(imc, (int, float)) and imc > 0:
            data['imc'] = float(imc)

        # SOPK / PCOS
        sopk = profile.get('sopk', False)
        if sopk is True or sopk == 'oui':
            data['pcos'] = 1
            factors.append('SOPK (syndrome des ovaires polykystiques)')

        # Antecedents familiaux
        if profile.get('acneFamilyHistory', False):
            data['antecedents_familiaux'] = 1
            factors.append("Antécédents familiaux d'acné")

        # Tabac
        if profile.get('smoker', False):
            data['fumeur'] = 1
            data['cigarettes'] = profile.get('cigarettesPerDay', 5)
            factors.append('Tabagisme')

        # Alcool
        alcool = str(profile.get('alcohol', 'jamais')).lower()
        data['alcool_jamais'] = 0
        data['alcool_occasionnel'] = 0
        data['alcool_régulier'] = 0
        if 'régulier' in alcool or 'regulier' in alcool:
            data['alcool_régulier'] = 1
            factors.append("Consommation régulière d'alcool")
        elif 'occasionnel' in alcool:
            data['alcool_occasionnel'] = 1
        else:
            data['alcool_jamais'] = 1

        # Type de peau — reset all one-hot, then set the right one
        for col in ['type_peau_acnéique', 'type_peau_déshydratée', 'type_peau_grasse',
                    'type_peau_mixte', 'type_peau_normale', 'type_peau_seche', 'type_peau_sensible']:
            data[col] = 0

        skin_raw = str(profile.get('skinType', 'mixte')).lower()
        skin_map = {
            'grasse':    'type_peau_grasse',
            'mixte':     'type_peau_mixte',
            'sèche':     'type_peau_seche',
            'seche':     'type_peau_seche',
            'sensible':  'type_peau_sensible',
            'normale':   'type_peau_normale',
            'acnéique':  'type_peau_acnéique',
            'acneique':  'type_peau_acnéique',
        }
        matched_skin_col = skin_map.get(skin_raw, 'type_peau_mixte')
        data[matched_skin_col] = 1
        if skin_raw in ['grasse', 'acnéique', 'acneique']:
            factors.append(f'Type de peau {skin_raw}')

        # Allergies cosmetiques
        allergies_list = profile.get('cosmeticAllergies', [])
        if allergies_list and 'aucune' not in allergies_list:
            data['allergies'] = 1

    # ── ETAPE 2 : Mapping des reponses quotidiennes ────────────────────────────

    # Phase hormonale — reset toutes les phases, puis en activer une
    data['phase_folliculaire'] = 0
    data['phase_luteale'] = 0
    data['phase_menstruelle'] = 0
    data['phase_ovulatoire'] = 0

    hormonal = str(answers.get('hormonal_cycle', 'folliculaire')).lower()
    if hormonal in ['pre_menstrual', 'lutéale', 'luteale', 'lutéal', 'luteal']:
        data['phase_luteale'] = 1
        data['jour_cycle'] = 24
        factors.append('Période prémenstruelle (pic hormonal)')
    elif hormonal in ['menstrual', 'menstruelle']:
        data['phase_menstruelle'] = 1
        data['jour_cycle'] = 2
        factors.append('Période menstruelle')
    elif hormonal in ['ovulatoire', 'ovulatory']:
        data['phase_ovulatoire'] = 1
        data['jour_cycle'] = 14
    else:
        data['phase_folliculaire'] = 1
        data['jour_cycle'] = 8

    # Alimentation
    diet_val = str(answers.get('diet', 'good')).lower()
    if diet_val == 'bad':
        data['alimentation_impact'] = 1.0
        factors.append('Alimentation pro-inflammatoire')
    elif diet_val == 'good':
        data['alimentation_impact'] = 0.1

    # Stress — FIX : 'high' etait ignore (le backend attendait 'very_high' uniquement)
    stress_val = str(answers.get('stress', 'medium')).lower()
    if stress_val == 'very_high':
        data['stress'] = 9
        factors.append('Stress très élevé')
    elif stress_val == 'high':
        data['stress'] = 8
        factors.append('Niveau de stress élevé')
    elif stress_val == 'medium':
        data['stress'] = 5
    else:
        data['stress'] = 2

    # Sommeil
    sleep_val = str(answers.get('sleep', 'good')).lower()
    if sleep_val == 'very_poor':
        data['sommeil'] = 3
        factors.append('Manque de sommeil sévère')
    elif sleep_val == 'poor':
        data['sommeil'] = 5
        factors.append('Manque de sommeil')
    else:
        data['sommeil'] = 8

    # Environnement
    if answers.get('temperature') == 'hot_humid':
        factors.append('Chaleur et humidité')

    # Routine de soins
    skincare_val = str(answers.get('skincare', 'regular')).lower()
    if skincare_val in ['none', 'sometimes']:
        data['lavage_2x/jour'] = 0
        data['lavage_parfois'] = 1
        data['lavage_1x/jour'] = 0
        factors.append('Routine de soins irrégulière')

    # --- ALGO 1 : CALCUL DU RISQUE IA ---
    # FIX #6 : Initialiser severity et spatial_factor avant le bloc conditionnel
    risk_score = 0.30
    shap_factors = {}
    explicability_method = "none"

    if pkl_model:
        try:
            df = pd.DataFrame([data])

            if hasattr(pkl_model, 'predict_proba'):
                raw_prob = pkl_model.predict_proba(df)[0]
                prob = float(raw_prob[1])
                logger.info(f"predict_proba classes={pkl_model.classes_} probas={raw_prob}")
            elif hasattr(pkl_model, 'predict'):
                prob = float(pkl_model.predict(df)[0])
                logger.warning(
                    f"predict_proba() indisponible. predict() brut={prob:.4f}. "
                    f"Si classifieur binaire le score sera toujours 0.0 ou 1.0."
                )
            else:
                raise AttributeError("Le modèle chargé n'a ni predict() ni predict_proba().")

            risk_score = max(0.0, min(1.0, prob))
            logger.info(
                f"risk_score final={risk_score:.4f} | "
                f"age={data['age']}, imc={data['imc']}, pcos={data['pcos']}, "
                f"stress={data['stress']}, sommeil={data['sommeil']}, "
                f"phase_luteale={data['phase_luteale']}, skin={skin_raw}"
            )

            # TENTATIVE DE VRAI SHAP (Local)
            try:
                import shap
                explainer = shap.Explainer(pkl_model)
                shap_values = explainer(df)

                vals = shap_values.values[0]
                if isinstance(vals[0], (list, np.ndarray)):  # Cas multiclasse
                    vals = vals[:, 1]

                feat_contrib = sorted(zip(df.columns, vals), key=lambda x: abs(x[1]), reverse=True)
                for name, val in feat_contrib[:3]:
                    pretty_name = name.replace('_', ' ').capitalize()
                    shap_factors[pretty_name] = float(abs(val))
                explicability_method = "SHAP (Local)"
                logger.info("✅ Explicabilité SHAP calculée avec succès.")

            except Exception as shap_err:
                logger.warning(f"⚠️ SHAP réel non disponible ({shap_err}). Repli sur Feature Importance.")
                if hasattr(pkl_model, 'feature_importances_'):
                    importances = pkl_model.feature_importances_
                    feat_imp = sorted(zip(df.columns, importances), key=lambda x: x[1], reverse=True)
                    for name, imp in feat_imp[:3]:
                        pretty_name = name.replace('_', ' ').capitalize()
                        shap_factors[pretty_name] = float(imp)
                    explicability_method = "Feature Importance (Global)"

            if not shap_factors:
                for i, f in enumerate(factors[:3]):
                    shap_factors[f] = 0.1 + (0.05 * i)
                explicability_method = "Rule-based (Simulated)"

        except Exception as e:
            logger.error(f"Erreur prédiction modèle: {e}")
    else:
        for i, f in enumerate(factors[:3]):
            shap_factors[f] = 0.1 + (0.05 * i)
        explicability_method = "None (Mock)"

    # Simulation Risk J+3
    risk_j3 = min(1.0, risk_score + 0.1) if data.get('phase_luteale') == 1 else max(0.0, risk_score - 0.05)

    # Determination du niveau
    level = "low"
    if risk_score >= 0.60:
        level = "high"
    elif risk_score >= 0.35:
        level = "medium"

    trend = "stable"
    if risk_j3 > risk_score:
        trend = "increasing"
    elif risk_j3 < risk_score:
        trend = "decreasing"

    # --- ALGO 2 : GENERATION DES RECOMMANDATIONS ---
    routine = ["Nettoyant doux au pH physiologique"]
    to_avoid = ["Gommages à grains", "Huiles comédogènes"]
    lifestyle = ["Dormir au moins 7h", "Limiter le sucre raffiné"]

    acne_treat = profile.get('acneTreatment', 'aucun')
    allergies = profile.get('cosmeticAllergies', [])

    if level == "low":
        strategy = "PRÉVENTION"
        routine.append("Sérum à la Vitamine C (éclat)")
        routine.append("Hydratation légère (gel-crème)")
    elif level == "medium":
        strategy = "ÉQUILIBRE"
        routine.append("Sérum à la Niacinamide (sébum)")
        routine.append("Hydratation équilibrante")
    else:
        strategy = "PROTECTION"
        routine.append("Sérum apaisant (Panthénol)")
        routine.append("Crème barrière réparatrice")
        to_avoid.append("Ingrédients actifs irritants")

    if data['phase_luteale'] == 1:
        routine.append("Double nettoyage le soir (indispensable)")
        lifestyle.append("Infusion de menthe poivrée (anti-androgène)")

    # Securite medicale (Priorite absolue)
    if acne_treat in ['isotrétinoïne', 'isotretinoïne', 'isotretinoine']:
        routine = ["Nettoyant SURGRAS", "Baume ultra-réparateur", "SPF 50+ (Indispensable)"]
        to_avoid.extend(["Rétinoïdes", "AHA", "BHA", "Gommages"])
        lifestyle.append("Hydratation labiale constante")
    elif acne_treat == 'antibiotiques':
        routine.append("Protection solaire renforcée")
        lifestyle.append("Cure de probiotiques (flore intestinale)")

    if allergies and 'aucune' not in allergies:
        to_avoid.append(f"⚠️ ÉVITER ABSOLUMENT : {', '.join(allergies)}")

    for factor in factors[:2]:
        if 'Stress' in factor:
            lifestyle.append("Séance de cohérence cardiaque (5 min)")
        if 'Alimentation' in factor:
            lifestyle.append("Augmenter les oméga-3 (noix, poissons gras)")
        if 'Sommeil' in factor:
            lifestyle.append("Rituel sans écran 30min avant le coucher")

    # FIX #8 : Validation et clamp du hygieneScore fourni par le frontend
    raw_hygiene = answers.get('hygieneScore', 70)
    hygiene_score = max(0, min(100, int(raw_hygiene))) if isinstance(raw_hygiene, (int, float)) else 70

    return {
        "id": f"pred_{uuid.uuid4().hex[:8]}",
        "riskScore": round(risk_score, 2),
        "riskJ3": round(risk_j3, 2),
        "riskLevel": level,
        "trend": trend,
        "shapFactors": shap_factors,
        "hygieneScore": hygiene_score,
        "cycleDay": data['jour_cycle'],
        "cyclePhase": answers.get('hormonal_cycle', 'folliculaire'),
        "routine": routine,
        "toAvoid": to_avoid,
        "lifestyle": lifestyle,
        "predictedAt": datetime.now().isoformat() + "Z"
    }
'''

start_marker = '    # FIX #5 : body est maintenant un PredictPayload valid'
end_marker = '@app.post("/detect")'

start_idx = content.find(start_marker)
end_idx = content.find(end_marker)

if start_idx == -1:
    print("ERROR: start marker not found!")
    # Try alternate
    start_marker2 = '    answers = body.answers'
    start_idx = content.find(start_marker2)
    print(f"Trying alternate marker, found at: {start_idx}")
    if start_idx == -1:
        exit(1)

if end_idx == -1:
    print("ERROR: end marker not found!")
    exit(1)

print(f"Replacing from index {start_idx} to {end_idx}")
new_content = content[:start_idx] + new_body + '\n\n' + content[end_idx:]

with open('main.py', 'w', encoding='utf-8') as f:
    f.write(new_content)

print("SUCCESS: main.py patched!")
print(f"Original size: {len(content)} | New size: {len(new_content)}")
