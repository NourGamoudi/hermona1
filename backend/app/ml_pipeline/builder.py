import pandas as pd
from .features import FEATURE_NAMES
from .defaults import BIOLOGICAL_DEFAULTS, USER_PROFILE_DEFAULTS
from .encoder import (
    encode_alcohol, encode_skin_type, encode_sport, 
    encode_cleansing, encode_hormonal_phase
)

class MLFeatureBuilder:
    @staticmethod
    def build_vector(answers: dict, cycle_day: int, cycle_phase: str) -> pd.DataFrame:
        """
        ML CONTEXTUAL PREDICTOR LAYER - FEATURE ASSEMBLY.
        
        Responsibility: Assembles raw user inputs and clinical engine outputs into a 40-feature vector.
        Restriction: No clinical logic, no biological hypotheses. Passive consumer only.
        Guarantees strict parity with LightGBM v1 features.
        """
        # 1. Initialize with all zeros to ensure no missing keys
        data = {name: 0.0 for name in FEATURE_NAMES}
        
        # 2. Inject Biological Defaults (Source: population means)
        data.update(BIOLOGICAL_DEFAULTS)
        
        profile = answers.get('profile', {})
        
        # 3. Numerical & Direct User Mappings
        data['age'] = float(profile.get('age', USER_PROFILE_DEFAULTS['age']))
        data['imc'] = float(profile.get('imc', USER_PROFILE_DEFAULTS['imc']))
        data['pcos'] = 1 if profile.get('sopk') in [True, 'oui', 1] else 0
        data['stress'] = float(answers.get('stress', USER_PROFILE_DEFAULTS['stress']))
        data['sommeil'] = float(answers.get('sleep', USER_PROFILE_DEFAULTS['sommeil']))
        data['jour_cycle'] = cycle_day
        data['soleil_heures'] = float(answers.get('sun_exposure', USER_PROFILE_DEFAULTS['soleil_heures']))
        data['protection_solaire'] = 1 if answers.get('spf') in [True, 'oui', 1] else 0
        data['allergies'] = 1 if profile.get('cosmeticAllergies') else 0
        data['antecedents_familiaux'] = 1 if profile.get('acneFamilyHistory') in [True, 'oui', 1] else 0
        data['maquillage'] = 1 if answers.get('makeup') in [True, 'oui', 1] else 0
        data['hydratation_verres'] = float(answers.get('water', USER_PROFILE_DEFAULTS['hydratation_verres']))
        data['fumeur'] = 1 if profile.get('smoker') in [True, 'oui', 1] else 0
        data['cigarettes'] = int(profile.get('cigarettesPerDay', USER_PROFILE_DEFAULTS['cigarettes']))
        
        # 4. Categorical Encodings
        data.update(encode_alcohol(profile.get('alcohol')))
        data.update(encode_skin_type(profile.get('skinType')))
        data.update(encode_sport(answers.get('sport')))
        data.update(encode_cleansing(answers.get('cleansing_frequency')))
        data.update(encode_hormonal_phase(cycle_phase))
        
        # 5. Final Assembly & Order Verification
        df = pd.DataFrame([data])
        
        # Hard-reorder to match FEATURE_NAMES
        df = df[FEATURE_NAMES]
        
        # Final Strict Assertion
        assert list(df.columns) == FEATURE_NAMES, "STRICT PARITY FAILURE: Order mismatch"
        
        return df
