def encode_alcohol(alc_str: str) -> dict:
    alc = str(alc_str or "").lower()
    mapping = {'alcool_jamais': 0, 'alcool_occasionnel': 0, 'alcool_rÚgulier': 0}
    if 'jamais' in alc: mapping['alcool_jamais'] = 1
    elif 'occasionnel' in alc: mapping['alcool_occasionnel'] = 1
    elif 'régulier' in alc or 'regulier' in alc: mapping['alcool_rÚgulier'] = 1
    else: mapping['alcool_jamais'] = 1
    return mapping

def encode_skin_type(skin_str: str) -> dict:
    st = str(skin_str or "").lower()
    mapping = {
        'type_peau_acnÚique': 0, 'type_peau_dÚshydratÚe': 0, 'type_peau_grasse': 0,
        'type_peau_mixte': 0, 'type_peau_normale': 0, 'type_peau_seche': 0, 'type_peau_sensible': 0
    }
    if 'grasse' in st: mapping['type_peau_grasse'] = 1
    elif 'mixte' in st: mapping['type_peau_mixte'] = 1
    elif 'sèche' in st or 'seche' in st: mapping['type_peau_seche'] = 1
    elif 'sensible' in st: mapping['type_peau_sensible'] = 1
    elif 'normale' in st: mapping['type_peau_normale'] = 1
    elif 'acnéique' in st or 'acneique' in st: mapping['type_peau_acnÚique'] = 1
    elif 'déshydratée' in st or 'deshydratee' in st: mapping['type_peau_dÚshydratÚe'] = 1
    else: mapping['type_peau_mixte'] = 1
    return mapping

def encode_sport(sport_str: str) -> dict:
    s = str(sport_str or "").lower()
    mapping = {'sport_1-2x/semaine': 0, 'sport_3-4x/semaine': 0, 'sport_jamais': 0}
    if '1-2' in s: mapping['sport_1-2x/semaine'] = 1
    elif '3-4' in s: mapping['sport_3-4x/semaine'] = 1
    elif 'jamais' in s: mapping['sport_jamais'] = 1
    else: mapping['sport_1-2x/semaine'] = 1
    return mapping

def encode_cleansing(cleansing_str: str) -> dict:
    c = str(cleansing_str or "").lower()
    mapping = {'lavage_1x/jour': 0, 'lavage_2x/jour': 0, 'lavage_3x/jour': 0, 'lavage_parfois': 0}
    if '1x' in c: mapping['lavage_1x/jour'] = 1
    elif '2x' in c: mapping['lavage_2x/jour'] = 1
    elif '3x' in c: mapping['lavage_3x/jour'] = 1
    elif 'parfois' in c: mapping['lavage_parfois'] = 1
    else: mapping['lavage_2x/jour'] = 1
    return mapping

def encode_hormonal_phase(phase_name: str) -> dict:
    """
    ML CONTEXTUAL PREDICTOR LAYER - TRANSFORMATION ONLY.
    
    Responsibility: Pure string-to-vector mapping.
    Restriction: No clinical logic, no biological assumptions, no recalculation.
    Consumes features pre-calculated by the Deterministic Clinical Engine.
    """
    phase = str(phase_name or "").lower()
    mapping = {'phase_folliculaire': 0, 'phase_luteale': 0, 'phase_menstruelle': 0, 'phase_ovulatoire': 0}
    
    if 'menstrual' in phase or 'menstruelle' in phase:
        mapping['phase_menstruelle'] = 1
    elif 'follicular' in phase or 'folliculaire' in phase:
        mapping['phase_folliculaire'] = 1
    elif 'ovulatory' in phase or 'ovulation' in phase or 'ovulatoire' in phase:
        mapping['phase_ovulatoire'] = 1
    elif 'luteal' in phase or 'luteale' in phase:
        mapping['phase_luteale'] = 1
        
    return mapping
