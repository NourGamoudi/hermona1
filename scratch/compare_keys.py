
def compare_keys(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    fr_start = content.find("'fr': {")
    en_start = content.find("'en': {")

    import re
    def get_keys(s):
        return set(re.findall(r"['\"](\w+)['\"]:", s))

    fr_map = content[fr_start:en_start]
    en_map = content[en_start:]

    fr_keys = get_keys(fr_map)
    en_keys = get_keys(en_map)

    only_fr = fr_keys - en_keys
    only_en = en_keys - fr_keys

    print("Keys only in FR:", sorted(list(only_fr)))
    print("Keys only in EN:", sorted(list(only_en)))

compare_keys('lib/core/localization/app_localizations.dart')
