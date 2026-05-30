# Official list of features for LightGBM v1 (5000 samples)
# Total: 40 features

FEATURE_NAMES = [
    'age', 'pcos', 'stress', 'sommeil', 'alimentation_impact',
    'LH', 'estradiol', 'progesterone', 'testosterone',
    'jour_cycle', 'soleil_heures', 'protection_solaire', 'allergies', 'antecedents_familiaux',
    'maquillage', 'hydratation_verres', 'fumeur', 'cigarettes', 'imc',
    
    # Alcool (One-Hot)
    'alcool_jamais', 'alcool_occasionnel', 'alcool_rÚgulier',
    
    # Type de Peau (One-Hot)
    'type_peau_acnÚique', 'type_peau_dÚshydratÚe', 'type_peau_grasse', 'type_peau_mixte',
    'type_peau_normale', 'type_peau_seche', 'type_peau_sensible',
    
    # Sport (One-Hot)
    'sport_1-2x/semaine', 'sport_3-4x/semaine', 'sport_jamais',
    
    # Lavage (One-Hot)
    'lavage_1x/jour', 'lavage_2x/jour', 'lavage_3x/jour', 'lavage_parfois',
    
    # Phase (One-Hot)
    'phase_folliculaire', 'phase_luteale', 'phase_menstruelle', 'phase_ovulatoire'
]
