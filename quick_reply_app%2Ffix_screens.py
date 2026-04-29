import os

lib = r'C:\Users\Administrator\.qclaw\workspace\quick-reply-app\quick_reply_app\lib\screens'

# home_screen.dart - SnackBar replacements around lines 230 and 266
path = os.path.join(lib, 'home_screen.dart')
with open(path, 'rb') as f:
    lines = f.read().decode('utf-8', errors='ignore').split('\n')

print(f'home_screen.dart has {len(lines)} lines')
# Find key patterns to locate where SnackBars should go
for i, line in enumerate(lines):
    if '_deleteMessage' in line or '宸插垹闄? in line or 'confirmDelete' in line or 'onDeleted' in line or '璇濇湳宸蹭繚瀛? in line:
        print(f'  {i+1}: {line.strip()[:100]}')
