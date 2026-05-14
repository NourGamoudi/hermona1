import sys
import os
import joblib
import pandas as pd
import json

# Add app to path
sys.path.append(os.path.join(os.getcwd(), 'app'))

try:
    from ml_pipeline.builder import MLFeatureBuilder
    from ml_pipeline.features import FEATURE_NAMES
    
    print("--- 1. Testing Modular Pipeline ---")
    
    sample_answers = {
        "profile": {
            "age": 22,
            "skinType": "grasse",
            "alcohol": "occasionnel",
            "sopk": True,
            "imc": 21.5
        },
        "stress": 8,
        "sleep": 4,
        "cycle_day": 21,
        "sport": "jamais",
        "cleansing_frequency": "2x/jour"
    }
    
    df = MLFeatureBuilder.build_vector(sample_answers)
    print(f"Vector Shape: {df.shape}")
    print(f"Parity with official list: {list(df.columns) == FEATURE_NAMES}")
    
    print("\n--- 2. Testing Model Inference ---")
    MODEL_PATH = 'model/modele_hermona_5000_20260415_221830 (1).pkl'
    if os.path.exists(MODEL_PATH):
        model = joblib.load(MODEL_PATH)
        print(f"Model Parity: {list(df.columns) == list(model.feature_names_in_)}")
        
        prediction = model.predict(df)[0]
        print(f"Prediction (Risk J+3): {prediction:.4f}")
        
        # Check SHAP Logic simulation (from main.py)
        risk_level = "high" if prediction > 0.6 else "medium" if prediction > 0.35 else "low"
        print(f"Level: {risk_level}")
    else:
        print(f"Model file not found at {MODEL_PATH}")

    print("\n--- 3. Cleanliness Check ---")
    # Search for legacy variables in the new pipeline
    import ml_pipeline.builder as builder
    import ml_pipeline.defaults as defaults
    
    legacy_found = False
    for mod in [builder, defaults]:
        content = open(mod.__file__, 'r', encoding='utf-8').read()
        if 'riskScore' in content or 'risk_today' in content:
            print(f"WARNING: Legacy variable found in {mod.__file__}")
            legacy_found = True
    
    if not legacy_found:
        print("SUCCESS: No legacy variables (riskScore/risk_today) found in ML pipeline.")

except Exception as e:
    import traceback
    traceback.print_exc()
