# Biological and synthetic constants for PFE Model Parity
# Values represent population means from the training dataset.

# --- SCIENTIFIC CALIBRATION (Source: verify_scientific_validity.py) ---
# Calculated based on 1000-sample distribution of LightGBM model
RISK_THRESHOLDS = {
    'LOW': 0.48,      # Percentile 33%
    'MEDIUM': 0.61,   # Percentile 66%
}

# SCIENTIFIC NOTE: These values are population constants used in the absence of 
# real-time biological sensors. They ensure model parity without inducing 
# localized bias while maintaining the hormonal profile required by LightGBM.
BIOLOGICAL_DEFAULTS = {
    'LH': 5.0,
    'estradiol': 50.0,
    'progesterone': 10.0,
    'testosterone': 0.5,
    'alimentation_impact': 0.5
}

USER_PROFILE_DEFAULTS = {
    'age': 25,
    'imc': 22.0,
    'stress': 5,
    'sommeil': 7,
    'jour_cycle': 14,
    'soleil_heures': 1.0,
    'hydratation_verres': 6,
    'cigarettes': 0
}
