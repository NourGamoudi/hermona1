
import re
import sys

# Ensure UTF-8 output
sys.stdout.reconfigure(encoding='utf-8')

def find_french_in_en(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    en_start = content.find("'en': {")
    if en_start == -1:
        print("Could not find en map")
        return

    en_map = content[en_start:]
    
    # Find all values in the en map
    values = re.findall(r":\s*['\"](.+?)['\"],", en_map)
    
    # Common French words/patterns
    # Excluding 'or' because it's also English
    french_patterns = [
        r'\b[ée]t\b', r'\b[ée]st\b', r'\ble\b', r'\bla\b', r'\bles\b', r'\bune\b', r'\bdes\b',
        r'\bdans\b', r'\bpour\b', r'\bavec\b', r'\bsans\b', r'\bsur\b', r'\bsous\b',
        r'\bmais\b', r'\bou\b', r'\bdonc\b', r'\bni\b', r'\bcar\b',
        r'[àâéèêëîïôûùç]',
    ]
    
    suspicious = []
    for v in values:
        if any(re.search(p, v, re.IGNORECASE) for p in french_patterns):
            # Exclude known OK English values that might trigger patterns
            # 'or' in "or something", 'a' in "a day" (already handled by \b)
            # 'pour' in "pour over" (rare)
            if v not in ['CeraVe', 'La Roche-Posay', 'Vichy', 'Avene', 'SPF (Essential)']:
                # Heuristic: if it contains a lot of French accented chars, it's likely French
                if re.search(r'[àâéèêëîïôûùç]', v):
                    suspicious.append(v)
                # If it contains "et", "le", "la" etc and NOT a lot of English common words
                elif any(re.search(p, v, re.IGNORECASE) for p in [r'\b[ée]t\b', r'\ble\b', r'\bla\b']):
                    if not any(re.search(p, v, re.IGNORECASE) for p in [r'\bthe\b', r'\band\b', r'\bwith\b']):
                        suspicious.append(v)

    print("Suspicious English values (likely French):")
    for s in suspicious:
        print(f" - {s}")

find_french_in_en('lib/core/localization/app_localizations.dart')
