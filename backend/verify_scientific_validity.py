import sys
import os
import joblib
import pandas as pd
import numpy as np
import json

# Add app to path
sys.path.append(os.path.join(os.getcwd(), 'app'))

try:
    from ml_pipeline.builder import MLFeatureBuilder
    
    MODEL_PATH = 'model/modele_hermona_5000_20260415_221830 (1).pkl'
    if not os.path.exists(MODEL_PATH):
        print(f"Error: Model not found at {MODEL_PATH}")
        sys.exit(1)
        
    model = joblib.load(MODEL_PATH)
    
    print("--- SCIENTIFIC CALIBRATION: RiskJ3 Distribution Analysis ---")
    
    # Generate 1000 synthetic samples to observe model behavior
    np.random.seed(42)
    predictions = []
    
    for _ in range(1000):
        # Create a randomized sample based on common ranges
        sample_answers = {
            "profile": {
                "age": np.random.randint(15, 45),
                "skinType": np.random.choice(["grasse", "mixte", "seche", "sensible"]),
                "alcohol": np.random.choice(["jamais", "occasionnel", "régulier"]),
                "sopk": np.random.choice([True, False]),
                "imc": np.random.uniform(18, 30)
            },
            "stress": np.random.randint(1, 11),
            "sleep": np.random.randint(3, 10),
            "cycle_day": np.random.randint(1, 29),
            "sport": np.random.choice(["jamais", "1-2x/semaine", "3-4x/semaine"]),
            "cleansing_frequency": np.random.choice(["1x/jour", "2x/jour", "parfois"])
        }
        
        df = MLFeatureBuilder.build_vector(sample_answers)
        pred = model.predict(df)[0]
        predictions.append(pred)
        
    predictions = np.array(predictions)
    
    # Calculate Quantiles
    q33 = np.quantile(predictions, 0.33)
    q66 = np.quantile(predictions, 0.66)
    
    print(f"Count: {len(predictions)}")
    print(f"Min: {predictions.min():.4f}")
    print(f"Max: {predictions.max():.4f}")
    print(f"Mean: {predictions.mean():.4f}")
    print(f"Median: {np.median(predictions):.4f}")
    print(f"Quantile 33% (Low/Medium threshold): {q33:.4f}")
    print(f"Quantile 66% (Medium/High threshold): {q66:.4f}")
    
    print("\n--- SCIENTIFIC RECOMMENDATION ---")
    print(f"For a balanced clinical distribution (33/33/33):")
    print(f"LOW Risk: < {q33:.2f}")
    print(f"MEDIUM Risk: {q33:.2f} - {q66:.2f}")
    print(f"HIGH Risk: > {q66:.2f}")

except Exception as e:
    import traceback
    traceback.print_exc()
