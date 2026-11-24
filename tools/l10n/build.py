#!/usr/bin/env python3
"""Builds lib/l10n/app_en.arb and app_hi.arb from t_*.py tables of (key, en, hi)."""
import glob, importlib.util, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'lib', 'l10n')

def load():
    rows = []
    for f in sorted(glob.glob(os.path.join(HERE, 't_*.py'))):
        spec = importlib.util.spec_from_file_location(os.path.basename(f)[:-3], f)
        m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
        rows += [(f, r[0], r[1], r[2], (r[3] if len(r) > 3 else {})) for r in m.T]
    return rows

def _parse(s, i, stop):
    """Returns (ordered placeholder names, plural names, next index) for an ICU message."""
    names, plurals = [], set()
    n = len(s)
    while i < n:
        c = s[i]
        if c == '}' and stop:
            return names, plurals, i + 1
        if c == '{':
            m = re.match(r'\{\s*([A-Za-z_]\w*)\s*([,}])', s[i:])
            if not m:
                raise ValueError('bad brace in: ' + s)
            name, sep = m.group(1), m.group(2)
            if name not in names:
                names.append(name)
            i += m.end()
            if sep == '}':
                continue
            kind = re.match(r'\s*(\w+)\s*,', s[i:])
            if not kind:
                raise ValueError('bad format in: ' + s)
            if kind.group(1) == 'plural':
                plurals.add(name)
            i += kind.end()
            while True:
                while i < n and s[i].isspace():
                    i += 1
                if s[i] == '}':
                    i += 1
                    break
                sel = re.match(r'[^\s{]+', s[i:])
                i += sel.end()
                while s[i].isspace():
                    i += 1
                assert s[i] == '{', s
                inner, ip, i = _parse(s, i + 1, True)
                for x in inner:
                    if x not in names:
                        names.append(x)
                plurals |= ip
            continue
        i += 1
    return names, plurals, i

def holders(msg):
    return set(_parse(msg, 0, False)[0])

def plural_names(msg):
    return _parse(msg, 0, False)[1]

def ordered(msg, opts):
    seen = _parse(msg, 0, False)[0]
    if 'order' in opts:
        assert sorted(opts['order']) == sorted(seen), (msg, opts, seen)
        return list(opts['order'])
    return seen

def main():
    rows = load()
    seen = {}
    errors = []
    en, hi = {}, {}
    for f, key, e, h, opts in rows:
        if key in seen:
            errors.append(f'duplicate key {key} ({seen[key]} and {os.path.basename(f)})'); continue
        seen[key] = os.path.basename(f)
        if not re.match(r'^[a-z][A-Za-z0-9]*$', key):
            errors.append(f'bad key {key}')
        for lang, msg in (('en', e), ('hi', h)):
            if "'" in msg:
                errors.append(f'{key}/{lang}: apostrophe; use the typographic one')
            if msg.count('{') != msg.count('}'):
                errors.append(f'{key}/{lang}: unbalanced braces')
            if not msg.strip():
                errors.append(f'{key}/{lang}: empty')
        if holders(e) != holders(h):
            errors.append(f'{key}: placeholders differ en={sorted(holders(e))} hi={sorted(holders(h))}')
        if plural_names(e) != plural_names(h):
            errors.append(f'{key}: plural names differ')
        en[key] = e; hi[key] = h
    if errors:
        print('\n'.join(errors)); sys.exit(1)

    def arb(lang, table):
        d = {'@@locale': lang}
        for f, key, e, h, opts in rows:
            d[key] = table[key]
            ph = ordered(en[key], opts)
            if lang == 'en' and ph:
                pn = plural_names(en[key]) | set(opts.get('ints', []))
                d['@' + key] = {'placeholders': {n: ({'type': 'int'} if n in pn else {'type': 'String'}) for n in ph}}
        return d
    os.makedirs(OUT, exist_ok=True)
    for lang, table in (('en', en), ('hi', hi)):
        with open(os.path.join(OUT, f'app_{lang}.arb'), 'w', encoding='utf-8') as fh:
            json.dump(arb(lang, table), fh, ensure_ascii=False, indent=2)
            fh.write('\n')
    print(f'{len(en)} strings -> {OUT}')

main()
