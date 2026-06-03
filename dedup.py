import re

file_path = r'c:\Users\asus\hermona1\lib\core\localization\app_localizations.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

def deduplicate_block(block_str):
    lines = block_str.split('\n')
    seen = set()
    out_lines = []
    for line in lines:
        # Match keys like 'key': 'value',
        match = re.match(r"^\s*'([^']+)':\s*'([^']*)',?$", line)
        if match:
            k = match.group(1)
            if k not in seen:
                seen.add(k)
                out_lines.append(line)
        else:
            out_lines.append(line)
    return '\n'.join(out_lines)

def process_map(match):
    prefix = match.group(1)
    body = match.group(2)
    suffix = match.group(3)
    deduped_body = deduplicate_block(body)
    return prefix + deduped_body + suffix

# Fix 'fr' block
content = re.sub(r"('fr':\s*\{)(.*?)(\},)", process_map, content, flags=re.DOTALL)
# Fix 'en' block
content = re.sub(r"('en':\s*\{)(.*?)(\};)", process_map, content, flags=re.DOTALL)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Deduplication done.")
