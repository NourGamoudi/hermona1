import joblib
import pandas as pd
import numpy as np
import lightgbm as lgb
import os

model_path = "model/modele_hermona_5000_20260415_221830 (1).pkl"
if os.path.exists(model_path):
    model = joblib.load(model_path)
    
    print("Features:")
    features = model.feature_name_
    importances = model.feature_importances_
    
    for f, imp in zip(features, importances):
        if f in ['LH', 'estradiol', 'progesterone', 'testosterone']:
            print(f"{f}: importance = {imp}")
            
    # Check if LightGBM tree strings reveal split thresholds
    trees = model.booster_.dump_model()
    
    import json
    with open('model_dump.json', 'w') as f:
        json.dump(trees, f)
    print("Dumped to json")
else:
    print("Model not found")
