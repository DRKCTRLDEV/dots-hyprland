# Localization system

One file per language in this directory (`de_DE.json`, `ru_RU.json`, …), plus
generated `manifest.json` and the tooling in `tools/i18n.py`. The runtime is
`services/Translation.qml`.

The English source text is the key, so files stay readable and hand-editable:

```json
{ "Dark": "Dunkel", "Copy path": "" }
```

An empty value means "untranslated" (falls back to English). There is no
`en_US.json` — English is the implicit source and the fallback. At runtime the
shell reads `manifest.json` + the one language file and does plain lookups —
no scanning, discovery or compilation. Language selection: `II_UI_LANG` env
var → `Config.options.language.ui` → system locale → its language family
(`pt_PT` → `pt_BR`) → English. User overrides live in
`~/.config/illogical-impulse/translations/<lang>.json` (same format) and win
over the bundled file.

Plurals use `Translation.trPlural("%1 notification", "%1 notifications", count)`
— count 1 → singular, else plural (French: 0 is singular; ja/zh/tr/vi/id
always use the plural). Missing translations never show raw keys or empty
strings.

## Tooling

```bash
cd dots/.config/quickshell/ii/translations/tools
./i18n.py status                 # per-language health
./i18n.py validate [--strict]    # all checks (exit 1 on errors)
./i18n.py extract                # strings found in QML/JS sources
./i18n.py manifest               # regenerate manifest.json
./i18n.py update [--prune]       # add missing keys; --prune drops unused
./i18n.py add pl_PL              # create a new language file
./i18n.py export de_DE --out de.csv   # CSV or PO
./i18n.py import de_DE de.csv
./i18n.py preview de_DE [--untranslated] [--html out.html]
./i18n.py format                 # normalize formatting
```

`validate` checks: missing/unused keys, duplicate keys, malformed JSON,
placeholder (`%1…%N`) consistency between key and translation, formatting
(sorting, whitespace, tabs), and manifest freshness.

## Workflow

**Translate a language:** `export de_DE --out de.csv` → translate the values
(keep `%1…%N`, `\n` and `<tt>…</tt>` markup; empty = untranslated) → `import
de_DE de.csv` → `validate` + `preview de_DE --untranslated`.

**Add a language:** `add pl_PL` → `manifest` → `validate`, then translate via
export/import. No application-code changes needed.

**After a refactor:** `update` (adds new keys) → review `validate` warnings →
`update --prune` to drop stale keys → `format`.

**Release:** `validate --strict` clean → `manifest` → commit language files +
manifest + source changes.

## Intentionally untranslated

`GlobalShortcut.description` (~70 protocol-metadata strings never rendered by
the shell), reusable-widget placeholder defaults, icons/symbols/URLs, and the
`shapes/example*.qml` demos.
