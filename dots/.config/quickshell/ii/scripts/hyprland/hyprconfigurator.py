#!/usr/bin/env python3
import os
import re
import sys
import tempfile


def format_value(value):
    if value in ("true", "false"):
        return value
    try:
        float(value)
        return value
    except ValueError:
        return f'"{value}"'


def build_nested_structure(key_parts, value):
    if len(key_parts) == 1:
        return f"{key_parts[0]}={format_value(value)}"
    else:
        return f"{key_parts[0]}={{{build_nested_structure(key_parts[1:], value)}}}"


WINDOW_RULE_PREFIX = "windowrule:"


def is_window_rule_key(key):
    return key.startswith(WINDOW_RULE_PREFIX)


def generate_config_line(key, value):
    if is_window_rule_key(key):
        rule = key[len(WINDOW_RULE_PREFIX) :]
        return f'hl.window_rule({{ match = {{ class = ".*" }}, {rule} = {format_value(value)} }})\n'
    key_parts = key.split(":")
    nested_structure = build_nested_structure(key_parts, value)
    return f"hl.config({{{nested_structure}}})\n"


def edit_hyprland_config(file_path, set_args, reset_args):
    if os.path.exists(file_path):
        with open(file_path, "r") as file:
            lines = file.readlines()
    else:
        lines = []

    set_dict = {k: v for k, v in set_args} if set_args else {}
    reset_set = set(reset_args) if reset_args else set()

    new_lines = []
    found_keys = set()

    patterns = {}
    for k in list(set_dict.keys()) + list(reset_set):
        if is_window_rule_key(k):
            rule = k[len(WINDOW_RULE_PREFIX) :]
            patterns[k] = re.compile(
                rf"^\s*hl\.window_rule\(\{{.*\b{re.escape(rule)}\s*="
            )
            continue
        key_parts = k.split(":")
        main_key = key_parts[0]
        if len(key_parts) > 1:
            pattern_parts = [rf"\s*{re.escape(part)}\s*=" for part in key_parts]
            nested_pattern = r"\{".join(pattern_parts)
            patterns[k] = re.compile(rf"^\s*hl\.config\(\{{\s*{nested_pattern}")
        else:
            patterns[k] = re.compile(
                rf"^\s*hl\.config\(\{{\s*{re.escape(main_key)}\s*="
            )

    for line in lines:
        matched = False

        for key in reset_set:
            if patterns[key].match(line):
                matched = True
                break

        if matched:
            continue

        for key, value in set_dict.items():
            if patterns[key].match(line):
                new_line = generate_config_line(key, value)
                new_lines.append(new_line)
                found_keys.add(key)
                matched = True
                break

        if matched:
            continue

        new_lines.append(line)

    if set_dict:
        for key, value in set_dict.items():
            if key not in found_keys:
                if new_lines and not new_lines[-1].endswith("\n"):
                    new_lines[-1] += "\n"
                new_lines.append(generate_config_line(key, value))

    dir_name = os.path.dirname(os.path.abspath(file_path))
    os.makedirs(dir_name, exist_ok=True)
    temp_path = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", dir=dir_name, delete=False
        ) as temp_file:
            temp_file.writelines(new_lines)
            temp_path = temp_file.name

        if os.path.exists(file_path):
            os.chmod(temp_path, os.stat(file_path).st_mode)
        else:
            os.chmod(temp_path, 0o644)

        os.replace(temp_path, file_path)
    except Exception as e:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)
        print(f"Error saving file: {e}")
        return

    for key in reset_set:
        print(f"Removed '{key}' from '{file_path}'")
    for key, value in set_dict.items():
        print(f"Updated '{file_path}' with {generate_config_line(key, value).strip()}")


if __name__ == "__main__":
    argv = sys.argv[1:]
    file_path = "~/.config/hypr/hyprland.conf"
    set_args = []
    reset_args = []

    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg == "--file" and i + 1 < len(argv):
            file_path = argv[i + 1]
            i += 2
        elif arg == "--set" and i + 2 < len(argv):
            set_args.append((argv[i + 1], argv[i + 2]))
            i += 3
        elif arg == "--reset" and i + 1 < len(argv):
            reset_args.append(argv[i + 1])
            i += 2
        else:
            i += 1

    file_path = os.path.expanduser(file_path)

    if not set_args and not reset_args:
        print("Error: Must specify at least one key to set or reset.")
    else:
        edit_hyprland_config(file_path, set_args, reset_args)
