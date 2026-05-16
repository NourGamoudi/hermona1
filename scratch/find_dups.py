
import re
from collections import Counter

def find_duplicates(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the start of 'fr' and 'en' maps
    fr_start = content.find("'fr': {")
    en_start = content.find("'en': {")

    if fr_start == -1:
        fr_start = content.find('"fr": {')
    if en_start == -1:
        en_start = content.find('"en": {')

    if fr_start == -1 or en_start == -1:
        print("Could not find fr or en maps")
        return

    fr_map = content[fr_start:en_start]
    en_map = content[en_start:]

    def get_keys(map_str):
        # Match both 'key': and "key":
        return re.findall(r"['\"](\w+)['\"]:", map_str)

    fr_keys = get_keys(fr_map)
    en_keys = get_keys(en_map)

    fr_dups = {k: c for k, c in Counter(fr_keys).items() if c > 1}
    en_dups = {k: c for k, c in Counter(en_keys).items() if c > 1}

    print("FR Duplicates:", fr_dups)
    print("EN Duplicates:", en_dups)

find_duplicates('lib/core/localization/app_localizations.dart')
