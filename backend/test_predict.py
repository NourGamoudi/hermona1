import pandas as pd
import joblib
import sys

try:
    model=joblib.load('C:/Users/asus/hermona1/backend/model/modele_hermona_5000_20260415_221830 (1).pkl')
    data={'age': 25, 'pcos': 0, 'stress': 5, 'sommeil': 7, 'alimentation_impact': 0.5, 'LH': 5.0, 'estradiol': 50.0, 'progesterone': 10.0, 'testosterone': 0.5, 'jour_cycle': 14, 'soleil_heures': 1.0, 'protection_solaire': 1, 'allergies': 0, 'antecedents_familiaux': 0, 'maquillage': 1, 'hydratation_verres': 6, 'fumeur': 0, 'cigarettes': 0, 'imc': 22.0, 'alcool_jamais': 1, 'alcool_occasionnel': 0, 'alcool_régulier': 0, 'type_peau_acnéique': 0, 'type_peau_déshydratée': 0, 'type_peau_grasse': 0, 'type_peau_mixte': 1, 'type_peau_normale': 0, 'type_peau_seche': 0, 'type_peau_sensible': 0, 'sport_1-2x/semaine': 1, 'sport_3-4x/semaine': 0, 'sport_jamais': 0, 'lavage_1x/jour': 0, 'lavage_2x/jour': 1, 'lavage_3x/jour': 0, 'lavage_parfois': 0, 'phase_folliculaire': 1, 'phase_luteale': 0, 'phase_menstruelle': 0, 'phase_ovulatoire': 0}
    df = pd.DataFrame([data])
    print("Features match:", list(df.columns) == list(model.feature_names_in_))
    if list(df.columns) != list(model.feature_names_in_):
        print("Model expected:", model.feature_names_in_)
        print("We provided:", df.columns)
    print("Predict result:", model.predict(df))
except Exception as e:
    import traceback
    traceback.print_exc()
