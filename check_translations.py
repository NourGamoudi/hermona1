import re

with open(r'c:\Users\asus\hermona1\lib\core\localization\app_localizations.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

fr_keys = set()
en_keys = set()

current_lang = None
for line in lines:
    line = line.strip()
    if line.startswith("'fr': {"):
        current_lang = 'fr'
        continue
    elif line.startswith("'en': {"):
        current_lang = 'en'
        continue
    elif line.startswith("},"):
        current_lang = None
        continue
    elif line == "};":
        current_lang = None
        continue
    
    if current_lang:
        match = re.match(r"'([^']+)'\s*:", line)
        if match:
            key = match.group(1)
            if current_lang == 'fr':
                fr_keys.add(key)
            elif current_lang == 'en':
                en_keys.add(key)

print(f"FR keys: {len(fr_keys)}")
print(f"EN keys: {len(en_keys)}")

missing_in_en = fr_keys - en_keys
print(f"Missing in EN: {len(missing_in_en)}")
for k in sorted(list(missing_in_en)):
    print(k)

missing_in_fr = en_keys - fr_keys
print(f"Missing in FR: {len(missing_in_fr)}")
for k in sorted(list(missing_in_fr)):
    print(k)

