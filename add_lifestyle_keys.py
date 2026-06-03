import re

file_path = r'c:\Users\asus\hermona1\lib\core\localization\app_localizations.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_keys = {
    'sleep_8h': ('Dormir 8h', 'Sleep 8h'),
    'drink_water': ("Boire de l'eau", 'Drink water'),
    'dont_touch_face': ('Ne pas toucher le visage', 'Do not touch face'),
    'hyaluronic_acid': ('Acide Hyaluronique', 'Hyaluronic Acid'),
    'strong_acids': ('Acides forts', 'Strong acids'),
    'security_mode': ('Mode sécurité', 'Security mode'),
    'fallback_disclaimer': ('Mode secours activé. Routine générique appliquée.', 'Emergency mode activated. Generic routine applied.'),
}

def escape_str(s):
    return s.replace("'", "\\'")

fr_adds = '\n'.join([f"      '{k}': '{escape_str(v[0])}'," for k, v in new_keys.items()])
en_adds = '\n'.join([f"      '{k}': '{escape_str(v[1])}'," for k, v in new_keys.items()])

content = re.sub(r"('fr':\s*\{)", r"\1\n" + fr_adds + "\n", content)
content = re.sub(r"('en':\s*\{)", r"\1\n" + en_adds + "\n", content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Updated app_localizations.dart with lifestyle keys')
