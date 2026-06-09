import re, subprocess, tempfile, os, sys

# Force UTF-8 output on Windows
sys.stdout.reconfigure(encoding='utf-8')

with open('pages/body.tex', 'r', encoding='utf-8') as f:
    content = f.read()

# Split by \chapter{
pat = re.compile(r'(?=\\chapter\{)')
parts = pat.split(content)
parts = [p for p in parts if p.strip()]

results = []
for ch in parts:
    m = re.search(r'\\chapter\{(.+?)\}', ch)
    title = m.group(1) if m else 'Preamble'

    tmp = tempfile.NamedTemporaryFile(mode='w', suffix='.tex', delete=False, encoding='utf-8')
    tmp.write(ch)
    tmp.close()

    out = subprocess.run(['texcount', '-total', '-inc', tmp.name], capture_output=True, text=True, encoding='utf-8')
    os.unlink(tmp.name)

    for line in out.stdout.split('\n'):
        if 'Words in text:' in line:
            wc = int(line.split(':')[1].strip())
            results.append((title, wc))
            break

total = sum(wc for _, wc in results)

# Print with numbered chapters
print(f'{"No.":<5} {"章节":<35} {"字数":>8}  {"占比":>6}')
print('-' * 58)
idx = 0
for title, wc in results:
    idx += 1
    if title == 'Preamble':
        continue
    pct = wc / total * 100
    bar = '#' * int(pct / 2)
    print(f'{idx:<5} {title:<35} {wc:>8}  {pct:>5.1f}%  {bar}')
print('-' * 58)
print(f'{"":5} {"合计":<35} {total:>8}')
