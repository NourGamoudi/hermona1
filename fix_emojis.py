import os

fixes = {
    'ðŸŒ': '🌍',
    'ðŸŒ™': '🌙',
    'ðŸ"': '📝',
    'ðŸ': '🧴',
    'ðŸŒŸ': '🌟',
    'Lutale': 'Lutéale',
    'communaut': 'communauté',
    '锰tape': 'Étape'
}

for root, _, files in os.walk('C:/Users/asus/hermona1/lib'):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            changed = False
            for wrong, right in fixes.items():
                if wrong in content:
                    content = content.replace(wrong, right)
                    changed = True
            if changed:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(content)
