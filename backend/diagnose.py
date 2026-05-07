import joblib
import pandas as pd
import numpy as np

MODEL_PATH = "backend/model/modele_hermona_v1.pkl"
model = joblib.load(MODEL_PATH)

print("=== TYPE DE MODÈLE ===")
print(type(model))

print("\n=== A predict_proba ? ===")
print(hasattr(model, 'predict_proba'))

# Profil extrême — tout au max
data_extreme = {
    'age': 25, 'pcos': 1, 'stress': 10, 'sommeil': 3, 'alimentation_impact': 1.0,
    'LH': 12.0, 'estradiol': 20.0, 'progesterone': 2.0, 'testosterone': 2.0,
    'jour_cycle': 24, 'soleil_heures': 0.0, 'protection_solaire': 0,
    'allergies': 1, 'antecedents_familiaux': 1, 'maquillage': 1,
    'hydratation_verres': 2, 'fumeur': 1, 'cigarettes': 10, 'imc': 30.0,
    'alcool_jamais': 0, 'alcool_occasionnel': 0, 'alcool_régulier': 1,
    'type_peau_acnéique': 1, 'type_peau_déshydratée': 0,
    'type_peau_grasse': 1, 'type_peau_mixte': 0, 'type_peau_normale': 0,
    'type_peau_seche': 0, 'type_peau_sensible': 1,
    'sport_1-2x/semaine': 0, 'sport_3-4x/semaine': 0, 'sport_jamais': 1,
    'lavage_1x/jour': 0, 'lavage_2x/jour': 0, 'lavage_3x/jour': 0, 'lavage_parfois': 1,
    'phase_folliculaire': 0, 'phase_luteale': 1, 'phase_menstruelle': 0, 'phase_ovulatoire': 0
}

# Profil neutre — tout par défaut
data_neutral = {
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

for label, data in [("EXTRÊME", data_extreme), ("NEUTRE", data_neutral)]:
    df = pd.DataFrame([data])
    print(f"\n=== PROFIL {label} ===")
    if hasattr(model, 'predict_proba'):
        probas = model.predict_proba(df)[0]
        print(f"  predict_proba : {probas}")
        print(f"  → risk_score  : {probas[1]:.4f}")
    pred = model.predict(df)[0]
    print(f"  predict()     : {pred}")

print("\n=== DISTRIBUTION SUR 1000 SAMPLES ALÉATOIRES ===")
np.random.seed(42)
scores = []
for _ in range(1000):
    sample = {k: np.random.choice([0, 1]) if isinstance(v, int) and v in [0,1]
              else np.random.uniform(0, 10) if k == 'stress'
              else v
              for k, v in data_neutral.items()}
    df = pd.DataFrame([sample])
    if hasattr(model, 'predict_proba'):
        scores.append(model.predict_proba(df)[0][1])
    else:
        scores.append(float(model.predict(df)[0]))

scores = np.array(scores)
print(f"  Min   : {scores.min():.4f}")
print(f"  Max   : {scores.max():.4f}")
print(f"  Moyen : {scores.mean():.4f}")
print(f"  >0.60 : {(scores > 0.6).sum()} / 1000 samples")
print(f"  >0.35 : {(scores > 0.35).sum()} / 1000 samples")