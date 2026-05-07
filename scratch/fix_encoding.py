import os

replacements = {
    "Ã©": "é",
    "Ã ": "à",
    "Ã": "à", 
    "Ã¨": "è",
    "Ãª": "ê",
    "Ã«": "ë",
    "Ã¹": "ù",
    "Ã»": "û",
    "Ã®": "î",
    "Ã¯": "ï",
    "Ã´": "ô",
    "Ã§": "ç",
    "Ã€": "À",
    "Ã‰": "É",
    "Ãˆ": "È",
    "ÃŠ": "Ê",
    "Ã‹": "Ë",
    "Ã™": "Ù",
    "Ã›": "Û",
    "ÃŽ": "Î",
    "Ã": "Ï",
    "Ã”": "Ô",
    "Ã‡": "Ç",
    "é”°": "é",
    "é”š": "â",
    "â‚¬": "à",
    "Déjé ": "Déjà",
    "é  faire": "à faire",
    "Ã°Å¸Å’¸": "🌸",
    "Ã°Å¸Å’¿": "🌿",
    "Ã°Å¸Å’â„¢": "🌙",
    "âÅ“¨": "✨",
    "Ã°Å¸" : "📸", 
    "Ã°Å¸§´": "🧼",
    "Ã°Å¸\"”¹": "📋",
    "Ã°Å¸\"¸": "📸",
    "âÅ“”¦": "✅",
    "â˜€ï¸ ": "☀️",
    "🌍™": "🌙",
    "🧴¥—": "🥗",
    "déjÏ ": "déjà",
    "caractÏ¨res": "caractères",
    "ðŸ”¥": "🔥",
    "é”°tape": "étape",
    "é”šge": "âge",
}

def fix_file(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        new_content = content
        for old, new in replacements.items():
            new_content = new_content.replace(old, new)
        
        if new_content != content:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Fixed: {path}")
    except Exception as e:
        print(f"Error fixing {path}: {e}")

def main():
    root = r"c:\Users\asus\hermona1\lib"
    for dirpath, dirnames, filenames in os.walk(root):
        for f in filenames:
            if f.endswith('.dart'):
                fix_file(os.path.join(dirpath, f))

if __name__ == "__main__":
    main()
