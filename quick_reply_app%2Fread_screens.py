import os, codecs

lib = r'C:\Users\Administrator\.qclaw\workspace\quick-reply-app\quick_reply_app\lib\screens'

checks = [
    ('search_screen.dart', range(278, 295)),
    ('send_screen.dart', range(262, 280)),
    ('home_screen.dart', range(124, 145)),
]

for fname, rng in checks:
    path = os.path.join(lib, fname)
    with open(path, 'rb') as f:
        lines = f.read().split(b'\n')
    print(f'=== {fname} ===')
    for i in rng:
        if i < len(lines):
            print(f'  {i+1}: {lines[i].decode("utf-8","ignore")[:120]}')
