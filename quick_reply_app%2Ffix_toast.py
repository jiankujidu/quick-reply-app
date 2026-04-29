import re, os

base = r'C:\Users\Administrator\.qclaw\workspace\quick-reply-app\quick_reply_app\lib\screens'

replacements = {
    'home_screen.dart': None,
    'search_screen.dart': None,
    'send_screen.dart': None,
}

for fname in replacements:
    path = os.path.join(base, fname)
    with open(path, encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # Replace Fluttertoast.showToast( msg: '...', backgroundColor: Colors.xxx )
    new_content = re.sub(
        r"Fluttertoast\.showToast\(\s*msg:\s*'([^']*)',\s*backgroundColor:\s*Colors\.(\w+)\s*\)",
        lambda m: (
            "ScaffoldMessenger.of(context).showSnackBar(\n"
            "        SnackBar(content: Text('" + m.group(1) + "'), "
            "backgroundColor: Colors." + m.group(2) + ", duration: Duration(seconds: 2)))"
        ),
        content
    )

    # Also replace any remaining Fluttertoast with just SnackBar (simpler cases)
    # e.g. Fluttertoast.showToast(msg: '...')
    new_content = re.sub(
        r"Fluttertoast\.showToast\(\s*msg:\s*'([^']*)',\s*toastLength:\s*Toast\.LENGTH_SHORT,\s*gravity:\s*ToastGravity\.BOTTOM\s*\)",
        lambda m: (
            "ScaffoldMessenger.of(context).showSnackBar(\n"
            "        SnackBar(content: Text('" + m.group(1) + "'), duration: Duration(seconds: 2)))"
        ),
        new_content
    )

    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)

    removed = content.count('Fluttertoast')
    print(f'Fixed {fname}: removed {removed} Fluttertoast calls')
