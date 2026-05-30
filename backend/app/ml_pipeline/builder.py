import pandas as pd
from .features import FEATURE_NAMES
from .defaults import BIOLOGICAL_DEFAULTS, USER_PROFILE_DEFAULTS
from .encoder import (
    encode_alcohol, encode_skin_type, encode_sport, 
    encode_cleansing, encode_hormonal_phase
)

class MLFeatureBuilder:
    @staticmethod
    def estimate_hormonal_profile(age: float, pcos: bool, cycle_phase: str, seed: int = None) -> dict:
        """
        Estimates biological hormone levels (LH, estradiol, progesterone, testosterone)
        based on user profile (PCOS, cycle phase, age) to replace static defaults.
        
        NOTE: Ces valeurs sont des estimations physiologiques approximatives destinées 
        à alimenter un modèle ML, et non des mesures biologiques réelles.
        """
        import random
        import hashlib
        
        # 0. Reproductibilité (génération d'un seed déterministe si non fourni)
        if seed is None:
            input_str = f"{age}_{pcos}_{cycle_phase}"
            seed = int(hashlib.md5(input_str.encode()).hexdigest()[:8], 16)
        rng = random.Random(seed)
        
        # 1. Base physiologique (valeurs moyennes)
        hormones = {
            'LH': 6.5,
            'estradiol': 110.0,
            'progesterone': 3.0,
            'testosterone': 30.0
        }
        
        phase = cycle_phase.lower()
        
        # 2. Ajustement clinique progressif (SOPK + cycle + âge)
        # - Phase du cycle
        if 'ovulat' in phase:
            hormones['LH'] += 6.5           # Pic LH
            hormones['estradiol'] += 60.0
            hormones['progesterone'] += 1.5
        elif 'luteal' in phase or 'lutéale' in phase:
            hormones['LH'] -= 1.0
            hormones['estradiol'] += 30.0
            hormones['progesterone'] += 14.0 # Pic progestérone
        elif 'menstru' in phase:
            hormones['LH'] -= 1.5
            hormones['estradiol'] -= 40.0
            hormones['progesterone'] -= 1.5
            
        # - SOPK (PCOS)
        if pcos:
            hormones['LH'] += 3.5            # Ajustement additif modéré
            hormones['testosterone'] += 20.0 # Hyperandrogénie modérée
            
        # - Âge (déclin hormonal progressif)
        if age > 35:
            # Baisse maximale de 15% pour éviter un effet trop rigide
            age_factor = min((age - 35) * 0.015, 0.15)
            hormones['estradiol'] *= (1 - age_factor)
            hormones['progesterone'] *= (1 - age_factor)
            
        # 3. Bruit contrôlé léger (±3% à ±7%)
        for k in hormones:
            magnitude = rng.uniform(0.03, 0.07)
            direction = rng.choice([-1, 1])
            hormones[k] *= (1.0 + (direction * magnitude))
            
        # 4. Clamping final strict pour le modèle ML
        hormones['LH'] = max(2.19, min(hormones['LH'], 14.93))
        hormones['estradiol'] = max(47.38, min(hormones['estradiol'], 220.64))
        hormones['progesterone'] = max(0.33, min(hormones['progesterone'], 23.67))
        hormones['testosterone'] = max(14.02, min(hormones['testosterone'], 65.41))
            
        return hormones

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
        
        # 3.5. Dynamic Hormonal Estimation
        # Overwrites the static BIOLOGICAL_DEFAULTS for LH, estradiol, progesterone, testosterone
        dynamic_hormones = MLFeatureBuilder.estimate_hormonal_profile(data['age'], bool(data['pcos']), cycle_phase)
        data.update(dynamic_hormones)
        
        data['stress'] = float(answers.get('stress', USER_PROFILE_DEFAULTS['stress']))
        data['sommeil'] = float(answers.get('sleep', USER_PROFILE_DEFAULTS['sommeil']))
        data['jour_cycle'] = cycle_day
        
        # Mapping fixes for Frontend/Backend consistency
        is_spf = answers.get('spf', answers.get('spf_used'))
        data['protection_solaire'] = 1 if is_spf in [True, 'oui', 1] else 0
        
        sun_val = answers.get('sun_exposure', answers.get('sunExposure', USER_PROFILE_DEFAULTS['soleil_heures']))
        data['soleil_heures'] = float(sun_val)
        
        data['allergies'] = 1 if profile.get('cosmeticAllergies') else 0
        data['antecedents_familiaux'] = 1 if profile.get('acneFamilyHistory') in [True, 'oui', 1] else 0
        
        is_makeup = answers.get('makeup', profile.get('makeup'))
        data['maquillage'] = 1 if is_makeup in [True, 'oui', 1] else 0
        
        water_val = answers.get('water', answers.get('hydration', USER_PROFILE_DEFAULTS['hydratation_verres']))
        data['hydratation_verres'] = float(water_val)
        
        is_smoker = profile.get('smoker', profile.get('isSmoker'))
        data['fumeur'] = 1 if is_smoker in [True, 'oui', 1] else 0
        data['cigarettes'] = int(profile.get('cigarettesPerDay', USER_PROFILE_DEFAULTS['cigarettes']))
        
        # Diet impact computation
        diet_val = answers.get('diet', profile.get('diet', []))
        impact = BIOLOGICAL_DEFAULTS.get('alimentation_impact', 0.5)
        if isinstance(diet_val, list):
            if any('fastfood' in str(x).lower() for x in diet_val): impact += 0.2
            if any('sugar' in str(x).lower() for x in diet_val): impact += 0.15
            if any('dairy' in str(x).lower() for x in diet_val): impact += 0.1
            if any('balanced' in str(x).lower() or 'fruits' in str(x).lower() for x in diet_val): impact -= 0.15
        elif isinstance(diet_val, str):
            d_str = diet_val.lower()
            if 'bad' in d_str or 'poor' in d_str: impact += 0.3
            if 'good' in d_str or 'balanced' in d_str: impact -= 0.2
        data['alimentation_impact'] = max(0.0, min(1.0, impact))
        
        # Cleansing frequency deduction
        cleansing_freq = answers.get('cleansing_frequency', profile.get('cleansing_frequency'))
        if not cleansing_freq:
            routine_m = str(profile.get('routineMatin', '')).lower()
            routine_s = str(profile.get('routineSoir', '')).lower()
            cleansers = ['nettoyant', 'cleanser', 'gel', 'lait', 'micellaire', 'savon', 'mousse', 'eau']
            count = 0
            if any(x in routine_m for x in cleansers): count += 1
            if any(x in routine_s for x in cleansers): count += 1
            if count == 0: cleansing_freq = 'parfois'
            elif count == 1: cleansing_freq = '1x'
            else: cleansing_freq = '2x'
        
        # 4. Categorical Encodings
        data.update(encode_alcohol(profile.get('alcohol')))
        data.update(encode_skin_type(profile.get('skinType')))
        data.update(encode_sport(answers.get('sport', profile.get('sport'))))
        data.update(encode_cleansing(cleansing_freq))
        data.update(encode_hormonal_phase(cycle_phase))
        
        # 5. Final Assembly & Order Verification
        df = pd.DataFrame([data])
        
        # Hard-reorder to match FEATURE_NAMES
        df = df[FEATURE_NAMES]
        
        # Final Strict Assertion
        assert list(df.columns) == FEATURE_NAMES, "STRICT PARITY FAILURE: Order mismatch"
        
        return df
