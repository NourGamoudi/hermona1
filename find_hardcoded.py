import os
import re

root_dir = r'c:\Users\asus\hermona1\lib'
french_chars = re.compile(r'[éèàêîôûç]')
suspicious_texts = []

for dirpath, _, filenames in os.walk(root_dir):
    for f in filenames:
        if f.endswith('.dart') and f != 'app_localizations.dart':
            filepath = os.path.join(dirpath, f)
            with open(filepath, 'r', encoding='utf-8') as file:
                try:
                    content = file.read()
                    matches = re.findall(r'Text\(\s*[\'\"](.*?)[\'\"]\s*\)', content)
                    for m in matches:
                        if m and not m.startswith('AppLocalizations'):
                            if french_chars.search(m) or ' ' in m:
                                suspicious_texts.append((filepath, m))
                except Exception as e:
                    pass

for p, text in suspicious_texts:
    print(f'{p}: {text}')
