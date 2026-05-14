def encode_alcohol(alc_str: str) -> dict:
    alc = str(alc_str or "").lower()
    mapping = {'alcool_jamais': 0, 'alcool_occasionnel': 0, 'alcool_régulier': 0}
    if 'jamais' in alc: mapping['alcool_jamais'] = 1
    elif 'occasionnel' in alc: mapping['alcool_occasionnel'] = 1
    elif 'régulier' in alc or 'regulier' in alc: mapping['alcool_régulier'] = 1
    else: mapping['alcool_jamais'] = 1
    return mapping

def encode_skin_type(skin_str: str) -> dict:
    st = str(skin_str or "").lower()
    mapping = {
        'type_peau_acnéique': 0, 'type_peau_déshydratée': 0, 'type_peau_grasse': 0,
        'type_peau_mixte': 0, 'type_peau_normale': 0, 'type_peau_seche': 0, 'type_peau_sensible': 0
    }
    if 'grasse' in st: mapping['type_peau_grasse'] = 1
    elif 'mixte' in st: mapping['type_peau_mixte'] = 1
    elif 'sèche' in st or 'seche' in st: mapping['type_peau_seche'] = 1
    elif 'sensible' in st: mapping['type_peau_sensible'] = 1
    elif 'normale' in st: mapping['type_peau_normale'] = 1
    elif 'acnéique' in st or 'acneique' in st: mapping['type_peau_acnéique'] = 1
    elif 'déshydratée' in st or 'deshydratee' in st: mapping['type_peau_déshydratée'] = 1
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

def calculate_hormonal_phase(day: int) -> dict:
    mapping = {'phase_folliculaire': 0, 'phase_luteale': 0, 'phase_menstruelle': 0, 'phase_ovulatoire': 0}
    if 1 <= day <= 5: mapping['phase_menstruelle'] = 1
    elif 6 <= day <= 13: mapping['phase_folliculaire'] = 1
    elif 14 <= day <= 16: mapping['phase_ovulatoire'] = 1
    else: mapping['phase_luteale'] = 1
    return mapping
