#!/usr/bin/env -S_/bin/sh_-c_"source_$(eval_echo_$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate&&exec_python_-E_"$0"_"$@""
"""
RivalCfg wrapper for Quickshell — compact, fully dynamic, supports every PID rivalcfg knows.
"""

import argparse, json, re, sys, contextlib
from typing import Any, Dict, List

try:
    import rivalcfg
    from rivalcfg.devices import PROFILES
    RIVALCFG_AVAILABLE = True
except ImportError:
    rivalcfg = PROFILES = None
    RIVALCFG_AVAILABLE = False

@contextlib.contextmanager
def _mouse():
    m = None
    try:
        yield None if not RIVALCFG_AVAILABLE else rivalcfg.get_first_mouse()
    finally:
        if m: m.close() if hasattr(m,'close') else None

def _clean(n): return re.sub(r'\s*\[[^\]]*\]|\s*\([^)]*\)','',str(n or '')).strip() if isinstance(n,str) else str(n or '')

def _conn_type(m):
    if not m: return "unknown"
    k = (m.vendor_id, m.product_id)
    if k in PROFILES:
        n = PROFILES[k].get("name","").lower()
        if any(x in n for x in ["2.4 ghz","wireless mode","wireless)"]): return "wireless"
        if "bluetooth" in n: return "bluetooth"
    return "bluetooth" if "bluetooth" in getattr(m,"name","").lower() else "wired"

def _run(f, base=None):
    r = base or {"success":False,"error":""}
    if not RIVALCFG_AVAILABLE:
        r["error"] = "rivalcfg not installed"
        return r
    with _mouse() as m:
        if not m:
            r["error"] = "No mouse connected"
            return r
        try: return f(m)
        except Exception as e:
            r["error"] = str(e)
            return r
    return r

def cmd_detect():
    r = {
        "available":False,"error":"","needs_udev_install":False,
        "device":{"name":"","pid":"","vendor_id":"","product_id":"","connection_type":"wired"},
        "battery":{"supported":False,"level":100,"is_charging":False},
        "capabilities":{"buttons":[],"has_sensitivity":False,"has_polling_rate":False,"has_buttons":False,
                        "sensitivity_range":{"min":100,"max":18000},"polling_rates":[]}
    }
    if not RIVALCFG_AVAILABLE:
        r["error"] = "rivalcfg not installed.\nPlease install it with: pip install rivalcfg"
        return r
    with _mouse() as m:
        if not m:
            r["error"] = "No SteelSeries mouse detected.\nMake sure your mouse is connected and udev rules are installed."
            r["needs_udev_install"] = True
            return r
        try:
            r["available"] = True
            r["device"].update({
                "name": _clean(m.name),
                "vendor_id": f"{m.vendor_id:04x}",
                "product_id": f"{m.product_id:04x}",
                "pid": f"{m.vendor_id:04x}_{m.product_id:04x}",
                "connection_type": _conn_type(m)
            })
            try:
                b = m.battery or {}
                if b.get("level") is not None:
                    r["battery"].update({"supported":True,"level":b.get("level",100) or 100,"is_charging":bool(b.get("is_charging"))})
            except: pass
            p = getattr(m,"mouse_profile",None) or PROFILES.get((m.vendor_id,m.product_id),{})
            s = p.get("settings",{}) if isinstance(p,dict) else {}
            for k in ["sensitivity"]+[f"sensitivity{i}" for i in range(1,6)]:
                if k in s:
                    r["capabilities"]["has_sensitivity"] = True
                    si = s[k]
                    if isinstance(si,dict):
                        if "input_range" in si and len(si["input_range"])>1:
                            r["capabilities"]["sensitivity_range"] = {"min":si["input_range"][0],"max":si["input_range"][1]}
                        elif "choices" in si:
                            try: cs = [int(x) for x in si["choices"] if str(x).isdigit()]
                            except: cs=[]
                            if cs: r["capabilities"]["sensitivity_range"] = {"min":min(cs),"max":max(cs)}
                    break
            if "polling_rate" in s:
                r["capabilities"]["has_polling_rate"] = True
                pi = s["polling_rate"]
                if isinstance(pi,dict) and "choices" in pi:
                    try: r["capabilities"]["polling_rates"] = sorted(int(x) for x in pi["choices"] if str(x).isdigit())
                    except: pass
            if "buttons_mapping" in s:
                r["capabilities"]["has_buttons"] = True
                bi = s["buttons_mapping"]
                if isinstance(bi,dict) and "buttons" in bi:
                    r["capabilities"]["buttons"] = [b for b in bi["buttons"] if b.lower().startswith("button")]
        except Exception as e: r["error"] = str(e); r["available"] = False
    return r

def cmd_battery(): return _run(lambda m: {
    "supported": bool((b:=m.battery or {}).get("level") is not None),
    "level": (b.get("level",100) or 100),
    "is_charging": bool(b.get("is_charging")),
    "error": ""
}, {"supported":False,"level":100,"is_charging":False,"error":""})

def cmd_set_sensitivity(p): return _run(lambda m: (
    (hasattr(m,"set_sensitivity") and m.set_sensitivity(p)) or
    any(getattr(m,f"set_sensitivity{i}",lambda x:None)(dpi) for i,dpi in enumerate(p,1)),
    m.save(), {"success":True,"error":""}
)[-1], {"success":False,"error":"Device does not support sensitivity adjustment"})

def cmd_set_polling_rate(r): return _run(lambda m: (
    hasattr(m,"set_polling_rate") and m.set_polling_rate(r) and m.save(),
    {"success":True,"error":""}
)[-1], {"success":False,"error":"Device does not support polling rate adjustment"})

def cmd_set_buttons(maps):
    aliases = {"Shift":"LeftShift","Ctrl":"LeftCtrl","Alt":"LeftAlt"}
    def inner(m):
        if any("+" in str(a) for a in maps.values()): raise ValueError("Key combos not supported")
        if not hasattr(m,"set_buttons_mapping"): raise ValueError("No button mapping support")
        parts = [f"{b.lower()}={aliases.get(a,a)}" for b,a in maps.items()] + ["layout=qwerty"]
        m.set_buttons_mapping(f"buttons({'; '.join(parts)})")
        m.save()
        return {"success":True,"error":""}
    return _run(inner, {"success":False,"error":""})

def cmd_reset(): return _run(lambda m: (m.reset_settings(), m.save(), {"success":True,"error":""})[-1])

def _parse_buttons(s):
    aliases = {"LeftShift":"Shift","RightShift":"Shift","LeftCtrl":"Ctrl","RightCtrl":"Ctrl","LeftAlt":"Alt"}
    r = {}
    if not s or not s.startswith("buttons("): return r
    for p in s[8:-1 if s.endswith(")") else None].split(";"):
        if "=" not in p: continue
        k,v = [x.strip() for x in p.split("=",1)]
        if k=="layout" or k.startswith("scroll"): continue
        if k.startswith("button"):
            bn = f"Button{k[6:]}"
            vl = v.lower()
            if vl != k and vl != "disabled":
                r[bn] = aliases.get(v,v)
            elif vl=="disabled" and k not in ("button7","button8","button9"):
                r[bn] = v
            elif k=="button6" and vl != "dpi":
                r[bn] = aliases.get(v,v)
    return r

def cmd_settings():
    def inner(m):
        s = m.mouse_settings
        sens = s.get("sensitivity")
        if sens is not None:
            sens = [int(x) for x in (sens if isinstance(sens,list) else str(sens).split(",")) if str(x).strip().isdigit()]
        else:
            sens = []
            for i in range(1,6):
                v = s.get(f"sensitivity{i}")
                if v is None: break
                try: sens.append(int(v))
                except: break
        return {
            "success":True,"error":"",
            "settings":{
                "sensitivity":sens,
                "polling_rate":int(s.get("polling_rate") or 1000),
                "buttons":_parse_buttons(s.get("buttons_mapping") or "")
            }
        }
    return _run(inner, {"success":False,"error":""})

def main():
    p = argparse.ArgumentParser(description="RivalCfg wrapper for Quickshell")
    sp = p.add_subparsers(dest="cmd")
    for c in ["detect","battery","reset","settings"]: sp.add_parser(c)
    s = sp.add_parser("sensitivity"); s.add_argument("presets")
    pr = sp.add_parser("polling-rate"); pr.add_argument("rate",type=int)
    b = sp.add_parser("buttons"); b.add_argument("mappings")
    a = p.parse_args()
    if not a.cmd: p.print_help(); sys.exit(1)
    h = {
        "detect": cmd_detect,
        "battery": cmd_battery,
        "sensitivity": lambda: cmd_set_sensitivity([int(x.strip()) for x in a.presets.split(",") if x.strip().isdigit()]),
        "polling-rate": lambda: cmd_set_polling_rate(a.rate),
        "buttons": lambda: cmd_set_buttons(json.loads(a.mappings)),
        "reset": cmd_reset,
        "settings": cmd_settings
    }
    print(json.dumps(h[a.cmd](), indent=2))

if __name__ == "__main__": main()