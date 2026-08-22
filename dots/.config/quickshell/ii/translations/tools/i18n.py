#!/usr/bin/env python3
import argparse
import csv
import datetime
import hashlib
import io
import json
import re
import sys
from pathlib import Path

SOURCE = "en_US"
DEFAULT = "en_US"
MANIFEST = "manifest.json"
PH = re.compile(r"%(?:L)?([1-9][0-9]*)")
VALID = re.compile(r"^[a-z]{2,3}(_[A-Z]{2})?$")

NAMES = {
    "de_DE": ("Deutsch", "German"),
    "en_GB": ("English (UK)", "English (UK)"),
    "en_US": ("English (US)", "English (US)"),
    "es_MX": ("Español", "Spanish"),
    "fr_FR": ("Français", "French"),
    "he_HE": ("עברית", "Hebrew"),
    "id_ID": ("Bahasa Indonesia", "Indonesian"),
    "it_IT": ("Italiano", "Italian"),
    "ja_JP": ("日本語", "Japanese"),
    "pt_BR": ("Português (Brasil)", "Portuguese"),
    "ru_RU": ("Русский", "Russian"),
    "tr_TR": ("Türkçe", "Turkish"),
    "uk_UA": ("Українська", "Ukrainian"),
    "vi_VN": ("Tiếng Việt", "Vietnamese"),
    "zh_CN": ("中文（简体）", "Chinese"),
}

FALLBACKS = {
    "de": "de_DE", "en": "en_US", "es": "es_MX", "fr": "fr_FR", "he": "he_HE",
    "id": "id_ID", "it": "it_IT", "ja": "ja_JP", "pt": "pt_BR", "ru": "ru_RU",
    "tr": "tr_TR", "uk": "uk_UA", "vi": "vi_VN", "zh": "zh_CN",
}

CALL = re.compile(r"Translation\.tr(?:Plural)?\s*\(")
ESC = {"n": "\n", "t": "\t", "r": "\r", "\\": "\\", '"': '"', "'": "'", "0": "\0"}


def decode(tok):
    out, i = [], 0
    while i < len(tok):
        c = tok[i]
        if c == "\\" and i + 1 < len(tok):
            n = tok[i + 1]
            if n == "u" and i + 5 < len(tok):
                try:
                    out.append(chr(int(tok[i + 2:i + 6], 16)))
                    i += 6
                    continue
                except ValueError:
                    pass
            out.append(ESC.get(n, n))
            i += 2
        else:
            out.append(c)
            i += 1
    return "".join(out)


def read_str(text, pos):
    if pos >= len(text) or text[pos] not in ('"', "'", "`"):
        return None, pos
    q, i, buf = text[pos], pos + 1, []
    while i < len(text):
        if text[i] == "\\":
            if i + 1 >= len(text):
                break
            buf.append(text[i:i + 2])
            i += 2
        elif text[i] == q:
            return decode("".join(buf)), i + 1
        else:
            buf.append(text[i])
            i += 1
    return None, pos


def skip(text, pos):
    while pos < len(text) and text[pos] in " \t\r\n,":
        pos += 1
    return pos


def extract(src):
    plain, pairs = set(), set()
    for ext in ("*.qml", "*.js"):
        for path in sorted(src.rglob(ext)):
            try:
                content = path.read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError):
                continue
            for m in CALL.finditer(content):
                is_plural = content[m.start():m.end()].startswith("Translation.trPlural")
                v, end = read_str(content, skip(content, m.end()))
                if v is None or not v.strip():
                    continue
                if not is_plural:
                    plain.add(v.strip())
                    continue
                s, end = read_str(content, skip(content, end))
                if s is not None:
                    pairs.add((v.strip(), s.strip()))
    return plain, pairs


def all_keys(plain, pairs):
    out = set(plain)
    for s, p in pairs:
        out.add(s)
        out.add(p)
    return out


def load(path):
    raw = path.read_text(encoding="utf-8")

    def hook(pairs):
        seen = {}
        for k, _ in pairs:
            seen[k] = seen.get(k, 0) + 1
        dups = [k for k, c in seen.items() if c > 1]
        if dups:
            raise ValueError(f"{path}: duplicate key(s): {', '.join(map(repr, dups[:10]))}")
        return dict(pairs)

    try:
        data = json.loads(raw, object_pairs_hook=hook)
    except json.JSONDecodeError as e:
        raise ValueError(f"{path}: invalid JSON: {e}")
    if not isinstance(data, dict):
        raise ValueError(f"{path}: expected a JSON object, got {type(data).__name__}")
    for k, v in data.items():
        if not isinstance(k, str) or not isinstance(v, str):
            raise ValueError(f"{path}: keys and values must be strings (bad entry: {k!r})")
    return data


def save(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
                    encoding="utf-8")


def lang_files(d):
    return sorted(p for p in d.glob("*.json") if p.name != MANIFEST)


def revision(s):
    return hashlib.sha256("\n".join(sorted(s)).encode()).hexdigest()[:12]


def build_manifest(d, src):
    plain, pairs = extract(src)
    codes = sorted({p.stem for p in lang_files(d)} | {SOURCE})
    return {
        "version": 2,
        "sourceLanguage": SOURCE,
        "defaultLanguage": DEFAULT,
        "generatedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "revision": revision(all_keys(plain, pairs)),
        "languages": [{"code": c, "nativeName": NAMES.get(c, (c, c))[0],
                       "englishName": NAMES.get(c, (c, c))[1]} for c in codes],
        "familyFallbacks": {f: FALLBACKS[f] for f in sorted(FALLBACKS)
                            if FALLBACKS[f] in codes},
    }


def load_manifest(d):
    p = d / MANIFEST
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else build_manifest(d, d.parent)


def analyze(valid, data):
    fk = set(data)
    ph = [(k, v) for k, v in data.items()
          if v and set(PH.findall(k)) != set(PH.findall(v))]
    return {"missing": sorted(valid - fk), "extra": sorted(fk - valid),
            "untranslated": sorted(k for k, v in data.items() if not v), "ph": ph}


def cmd_manifest(args):
    save(args.translations_dir / MANIFEST, build_manifest(args.translations_dir, args.source_dir))
    man = load_manifest(args.translations_dir)
    print(f"Wrote {args.translations_dir / MANIFEST}")
    print(f"  {len(man['languages'])} languages, revision {man['revision']}")
    return 0


def cmd_status(args):
    plain, pairs = extract(args.source_dir)
    valid = all_keys(plain, pairs)
    print(f"{'language':8} {'keys':>5} {'translated':>10} {'%':>6} {'missing':>7} {'extra':>5} {'ph-err':>6}")
    for path in lang_files(args.translations_dir):
        data = load(path)
        a = analyze(valid, data)
        translated = len(data) - len(a["untranslated"])
        pct = 100.0 * translated / len(data) if data else 0.0
        print(f"{path.stem:8} {len(data):5} {translated:10} {pct:6.1f} {len(a['missing']):7} "
              f"{len(a['extra']):5} {len(a['ph']):6}")
    print(f"(source: {len(valid)} strings extracted from code, no {SOURCE}.json)")
    return 0


def cmd_extract(args):
    plain, pairs = extract(args.source_dir)
    if args.json:
        print(json.dumps({"tr": sorted(plain), "trPlural": sorted(pairs)}, ensure_ascii=False, indent=2))
    else:
        for s in sorted(plain):
            print(s)
        for s, p in sorted(pairs):
            print(f"[plural] {s} / {p}")
    print(f"{len(plain)} tr(), {len(pairs)} trPlural() pairs", file=sys.stderr)
    return 0


def cmd_update(args):
    plain, pairs = extract(args.source_dir)
    valid = all_keys(plain, pairs)
    for path in lang_files(args.translations_dir):
        data = load(path)
        missing = sorted(valid - set(data))
        extra = sorted(set(data) - valid) if args.prune else []
        for k in missing:
            data[k] = ""
        for k in extra:
            del data[k]
        save(path, data)
        parts = [f"added {len(missing)}"]
        if extra or args.prune:
            parts.append(f"removed {len(extra)}")
        print(f"{path.stem}: {', '.join(parts)}")
    return 0


def cmd_add(args):
    if not VALID.match(args.lang):
        print(f"error: {args.lang!r} is not a valid language code (use e.g. 'de', 'pt_BR')",
              file=sys.stderr)
        return 1
    out = args.translations_dir / f"{args.lang}.json"
    if out.exists():
        print(f"error: {out} already exists", file=sys.stderr)
        return 1
    plain, pairs = extract(args.source_dir)
    save(out, {k: "" for k in sorted(all_keys(plain, pairs))})
    print(f"Created {out} ({len(all_keys(plain, pairs))} keys, untranslated).")
    print("Next: translate via 'export'/'import', then 'i18n.py manifest' and 'i18n.py validate'.")
    return 0


def _csv_export(data):
    buf = io.StringIO()
    w = csv.writer(buf)
    w.writerow(["key", "translation"])
    for k in sorted(data):
        w.writerow([k, data[k]])
    return buf.getvalue()


def _po_escape(s):
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\t", "\\t")


def _po_unescape(s):
    return s.replace('\\"', '"').replace("\\n", "\n").replace("\\t", "\t").replace("\\\\", "\\")


def _po_export(data):
    out = ['msgid ""', 'msgstr ""', '"Content-Type: text/plain; charset=UTF-8\\n"', '""']
    for k in sorted(data):
        out.append(f'msgid "{_po_escape(k)}"')
        out.append(f'msgstr "{_po_escape(data[k])}"')
        out.append("")
    return "\n".join(out)


def _po_parse(text):
    entries, msgid, parts, in_msgstr = {}, None, [], False
    for line in text.splitlines():
        if line.startswith("#"):
            continue
        if line.startswith('msgid "'):
            if msgid is not None:
                entries[msgid] = _po_unescape("".join(parts))
            msgid, parts, in_msgstr = _po_unescape(line[7:-1]), [], False
        elif line.startswith('msgstr "'):
            in_msgstr = True
            parts.append(line[8:-1])
        elif in_msgstr and line.startswith('"') and line.endswith('"'):
            parts.append(line[1:-1])
        elif msgid is not None and not line.strip():
            entries[msgid] = _po_unescape("".join(parts))
            msgid = None
    if msgid is not None:
        entries[msgid] = _po_unescape("".join(parts))
    return entries


def cmd_export(args):
    path = args.translations_dir / f"{args.lang}.json"
    if not path.exists():
        print(f"error: {path} does not exist", file=sys.stderr)
        return 1
    data = load(path)
    fmt = args.format or ("po" if str(args.out or "").endswith(".po") else "csv")
    text = _po_export(data) if fmt == "po" else _csv_export(data)
    if args.out:
        Path(args.out).write_text(text, encoding="utf-8")
        print(f"Wrote {args.out}")
    else:
        sys.stdout.write(text)
    return 0


def cmd_import(args):
    path = args.translations_dir / f"{args.lang}.json"
    if not path.exists():
        print(f"error: {path} does not exist", file=sys.stderr)
        return 1
    src = Path(args.file)
    if not src.exists():
        print(f"error: {src} does not exist", file=sys.stderr)
        return 1
    text = src.read_text(encoding="utf-8")
    if src.suffix.lower() == ".po":
        incoming = _po_parse(text)
    else:
        rows = list(csv.DictReader(io.StringIO(text)))
        incoming = {r["key"]: r["translation"] for r in rows if r.get("key")}
    data = load(path)
    updated = added = skipped = 0
    for k, v in incoming.items():
        if not isinstance(v, str):
            continue
        if k not in data:
            if args.add:
                data[k], added = v, added + 1
            else:
                skipped += 1
        elif v != data[k]:
            data[k], updated = v, updated + 1
    save(path, data)
    print(f"Imported into {args.lang}: updated {updated}, added {added}, skipped {skipped}.")
    return 0


def cmd_preview(args):
    path = args.translations_dir / f"{args.lang}.json"
    if not path.exists():
        print(f"error: {path} does not exist", file=sys.stderr)
        return 1
    data = load(path)
    rows = [(k, v, not v) for k, v in sorted(data.items()) if not args.untranslated or not v]
    if args.html:
        body = "".join(
            f'<tr class="{"untranslated" if unt else "ok"}"><td class="key">{_po_escape(k)}</td>'
            f"<td>{_po_escape(v)}</td></tr>" for k, v, unt in rows)
        html = ("<!doctype html><html><head><meta charset='utf-8'><title>"
                f"Preview {args.lang}</title><style>body{{font-family:sans-serif;margin:2rem}}"
                "table{border-collapse:collapse;width:100%}td,th{border:1px solid #ddd;padding:6px;"
                "text-align:left}.untranslated td{background:#fff0f0}.key{color:#888;font-size:.85em}"
                "</style></head><body><h1>Preview: " + args.lang + "</h1><table>"
                "<tr><th>key</th><th>translation</th></tr>" + body + "</table></body></html>")
        Path(args.html).write_text(html, encoding="utf-8")
        print(f"Wrote {args.html} ({len(rows)} rows)")
    else:
        for k, v, unt in rows:
            print(f"{k}\n  {args.lang}: {v}{' [UNTRANSLATED]' if unt else ''}")
    return 0


def cmd_format(args):
    for path in lang_files(args.translations_dir):
        save(path, load(path))
        print(f"formatted {path.name}")
    return 0


def cmd_validate(args):
    errors, warnings = [], []
    plain, pairs = extract(args.source_dir)
    valid = all_keys(plain, pairs)

    for path in lang_files(args.translations_dir):
        code = path.stem
        try:
            data = load(path)
        except ValueError as e:
            errors.append(str(e))
            continue
        a = analyze(valid, data)
        for k in a["missing"]:
            errors.append(f"[{code}] missing key: {k!r} — run 'i18n.py update'")
        for k in a["extra"]:
            warnings.append(f"[{code}] unused key: {k!r} — run 'i18n.py update --prune'")
        for k, v in a["ph"]:
            errors.append(f"[{code}] placeholder mismatch {k!r} -> {v!r}")
        for k, v in data.items():
            if v != v.rstrip():
                warnings.append(f"[{code}] trailing whitespace in value of {k!r}")
            if "\t" in v:
                warnings.append(f"[{code}] tab character in value of {k!r}")
        if list(data) != sorted(data):
            warnings.append(f"[{code}] keys not sorted — run 'i18n.py format'")

    man = load_manifest(args.translations_dir)
    codes = {p.stem for p in lang_files(args.translations_dir)}
    man_codes = {l["code"] for l in man.get("languages", [])}
    for c in sorted(codes - man_codes):
        errors.append(f"[manifest] language file {c}.json not registered in manifest.json")
    for c in sorted(man_codes - codes):
        if c != SOURCE:
            errors.append(f"[manifest] {c} registered in manifest but has no language file")
    if man.get("revision") != revision(valid):
        warnings.append("[manifest] stale revision — run 'i18n.py manifest'")

    for msg in sorted(errors):
        print(f"error: {msg}")
    for msg in sorted(warnings):
        print(f"warning: {msg}")
    print(f"\n{len(errors)} error(s), {len(warnings)} warning(s)")
    return 1 if errors or (warnings and args.strict) else 0


def main(argv=None):
    parser = argparse.ArgumentParser(
        prog="i18n.py",
        description="Translation tooling for illogical-impulse. Prepares manifest.json and "
                    "validates/syncs language files; nothing runs at shell runtime.")
    parser.add_argument("-t", "--translations-dir", type=Path,
                        default=Path(__file__).resolve().parent.parent)
    parser.add_argument("-s", "--source-dir", type=Path,
                        default=Path(__file__).resolve().parent.parent.parent)
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("manifest", help="regenerate translations/manifest.json")
    p.set_defaults(func=cmd_manifest)

    p = sub.add_parser("status", help="per-language health summary")
    p.set_defaults(func=cmd_status)

    p = sub.add_parser("extract", help="print strings extracted from sources")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_extract)

    p = sub.add_parser("update", help="add missing keys (from code) to all languages")
    p.add_argument("--prune", action="store_true", help="also drop keys not in the source")
    p.set_defaults(func=cmd_update)

    p = sub.add_parser("add", help="create a new language file")
    p.add_argument("lang")
    p.set_defaults(func=cmd_add)

    p = sub.add_parser("export", help="export a language to CSV or PO")
    p.add_argument("lang")
    p.add_argument("--format", choices=["csv", "po"])
    p.add_argument("--out")
    p.set_defaults(func=cmd_export)

    p = sub.add_parser("import", help="import translations from CSV or PO")
    p.add_argument("lang")
    p.add_argument("file")
    p.add_argument("--add", action="store_true", help="add keys missing from the language file")
    p.set_defaults(func=cmd_import)

    p = sub.add_parser("preview", help="preview a language (console or --html)")
    p.add_argument("lang")
    p.add_argument("--untranslated", action="store_true")
    p.add_argument("--html")
    p.set_defaults(func=cmd_preview)

    p = sub.add_parser("format", help="normalize formatting of all language files")
    p.set_defaults(func=cmd_format)

    p = sub.add_parser("validate", help="run all checks (exit 1 on errors)")
    p.add_argument("--strict", action="store_true", help="treat warnings as errors")
    p.set_defaults(func=cmd_validate)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
