import os

def fix_encoding(filepath):
    # Mapping of common UTF-8 double-encoding artifacts to their correct characters
    replacements = {
        'Ã©': 'é',
        'Ã¨': 'è',
        'Ã ': 'à',
        'Ãª': 'ê',
        'â€™': "'",
        'âœ¨': '✨',
        'Ã¢': 'â',
        'Ã®': 'î',
        'Ã§': 'ç',
        'Ã»': 'û',
        'Ã´': 'ô',
        'Â°': '°',
        'Ã‹': 'Ë',
        'Ã‰': 'É',
        'Ãˆ': 'È',
        'Ã€': 'À',
        'â†’': '→',
        'â€œ': '"',
        'â€”': '—',
        'â€': '”',
        'â€ ': ' ', # sometimes trailing spaces
        'Ã¯': 'ï',
        'Ã¶': 'ö',
        'Ã¼': 'ü',
        'Ã¤': 'ä',
        'Ã±': 'ñ',
        'â€¦': '...',
    }

    try:
        # Read the file with utf-8
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content
        
        # Apply replacements
        for wrong, right in replacements.items():
            content = content.replace(wrong, right)

        # If content changed, save it back
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Fixed: {filepath}")
            
    except Exception as e:
        print(f"Error processing {filepath}: {e}")

def main():
    lib_path = r'C:\Users\asus\hermona1\lib'
    for root, _, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                fix_encoding(filepath)

if __name__ == "__main__":
    main()
