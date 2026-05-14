import joblib
import pandas as pd
from app.services.feature_engineer import FeatureEngineer
import os

# Mock pkl_model
class MockModel:
    def __init__(self):
        self.feature_names_in_ = [
            'age', 'pcos', 'stress', 'sommeil', 'alimentation_impact', 'LH', 'estradiol', 
            'progesterone', 'testosterone', 'jour_cycle', 'soleil_heures', 'protection_solaire', 
            'allergies', 'antecedents_familiaux', 'maquillage', 'hydratation_verres', 'fumeur', 
            'cigarettes', 'imc', 'alcool_jamais', 'alcool_occasionnel', 'alcool_régulier', 
            'type_peau_acnéique', 'type_peau_déshydratée', 'type_peau_grasse', 'type_peau_mixte', 
            'type_peau_normale', 'type_peau_seche', 'type_peau_sensible', 'sport_1-2x/semaine', 
            'sport_3-4x/semaine', 'sport_jamais', 'lavage_1x/jour', 'lavage_2x/jour', 
            'lavage_3x/jour', 'lavage_parfois', 'phase_folliculaire', 'phase_luteale', 
            'phase_menstruelle', 'phase_ovulatoire'
        ]

def test_engineer():
    print("--- Testing FeatureEngineer ---")
    mock = MockModel()
    answers = {
        "profile": {
            "age": 22,
            "skinType": "grasse",
            "alcohol": "occasionnel",
            "sopk": True
        },
        "stress": 8,
        "sleep": 4,
        "cycle_day": 21,
        "sport": "jamais"
    }
    
    df = FeatureEngineer.prepare_features(answers, mock.feature_names_in_)
    print(f"Shape: {df.shape}")
    print(f"Columns match: {list(df.columns) == mock.feature_names_in_}")
    
    print("\nSample values:")
    print(f"  age: {df['age'].iloc[0]}")
    print(f"  pcos: {df['pcos'].iloc[0]}")
    print(f"  type_peau_grasse: {df['type_peau_grasse'].iloc[0]}")
    print(f"  alcool_occasionnel: {df['alcool_occasionnel'].iloc[0]}")
    print(f"  phase_luteale: {df['phase_luteale'].iloc[0]}")
    print(f"  sport_jamais: {df['sport_jamais'].iloc[0]}")
    
    if list(df.columns) != mock.feature_names_in_:
        print("ERROR: Column mismatch!")
    else:
        print("SUCCESS: Feature Engineer is ready.")

if __name__ == "__main__":
    test_engineer()
