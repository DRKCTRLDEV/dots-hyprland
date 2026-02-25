#!/usr/bin/env -S\_/bin/sh\_-c\_"source\_\$(eval\_echo\_\$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate&&exec\_python\_-E\_"\$0"\_"\$@""
"""
RivalCfg Python Wrapper for Quickshell integration.
Provides JSON-based interface to rivalcfg Python library for configuring SteelSeries mice.
"""
import argparse
import json
import sys
from typing import Any, Dict, List, Optional


def get_mouse():
    """Get the first connected SteelSeries mouse."""
    try:
        import rivalcfg
        mouse = rivalcfg.get_first_mouse()
        return mouse
    except ImportError:
        return None
    except Exception:
        return None


def cmd_detect() -> Dict[str, Any]:
    """Detect connected SteelSeries mouse and return device info."""
    result: Dict[str, Any] = {
        "available": False,
        "error": "",
        "needs_udev_install": False
    }
    result["device"] = {
        "name": "",
        "pid": "",
        "vendor_id": "",
        "product_id": "",
        "connection_type": "unknown"
    }
    result["battery"] = {
        "supported": False,
        "level": 100,
        "is_charging": False
    }
    result["capabilities"] = {
        "buttons": [],
        "has_sensitivity": False,
        "has_polling_rate": False,
        "has_buttons": False,
        "sensitivity_range": {"min": 100, "max": 18000},
        "polling_rates": []
    }
    
    mouse = get_mouse()
    if mouse is None:
        # Check if rivalcfg is installed
        try:
            import rivalcfg
            # rivalcfg is installed but no device found - could be udev rules issue
            result["error"] = "No SteelSeries mouse detected.\nMake sure your mouse is connected and udev rules are installed."
            result["needs_udev_install"] = True
        except ImportError:
            result["error"] = "rivalcfg not installed.\nPlease install it with: pip install rivalcfg"
        return result
    
    try:
        # Basic device info
        result["available"] = True
        result["device"]["name"] = mouse.name
        result["device"]["vendor_id"] = f"{mouse.vendor_id:04x}"
        result["device"]["product_id"] = f"{mouse.product_id:04x}"
        result["device"]["pid"] = f"{mouse.vendor_id:04x}_{mouse.product_id:04x}"
        
        # Determine connection type from device name
        name_lower = mouse.name.lower()
        if "wireless" in name_lower or "2.4" in name_lower:
            result["device"]["connection_type"] = "wireless"
        elif "bluetooth" in name_lower:
            result["device"]["connection_type"] = "bluetooth"
        else:
            result["device"]["connection_type"] = "wired"
        
        # Check battery support
        try:
            battery_info = mouse.battery
            if battery_info:
                result["battery"]["supported"] = True
                result["battery"]["level"] = battery_info.get("level", 100) or 100
                result["battery"]["is_charging"] = battery_info.get("is_charging", False) or False
        except Exception:
            pass
        
        # Check device capabilities from profile
        profile = mouse.mouse_profile
        if profile and "settings" in profile:
            settings = profile["settings"]
            
            # Check sensitivity/DPI support
            # Newer mice use a combined "sensitivity" key; older ones use "sensitivity1", "sensitivity2", etc.
            if "sensitivity" in settings:
                result["capabilities"]["has_sensitivity"] = True
                sens_info = settings["sensitivity"]
                if "input_range" in sens_info:
                    result["capabilities"]["sensitivity_range"]["min"] = sens_info["input_range"][0]
                    result["capabilities"]["sensitivity_range"]["max"] = sens_info["input_range"][1]
            elif "sensitivity1" in settings:
                result["capabilities"]["has_sensitivity"] = True
                sens_info = settings["sensitivity1"]
                if "input_range" in sens_info:
                    result["capabilities"]["sensitivity_range"]["min"] = sens_info["input_range"][0]
                    result["capabilities"]["sensitivity_range"]["max"] = sens_info["input_range"][1]
                elif "choices" in sens_info:
                    choices = sorted(sens_info["choices"].keys())
                    if choices:
                        result["capabilities"]["sensitivity_range"]["min"] = choices[0]
                        result["capabilities"]["sensitivity_range"]["max"] = choices[-1]
            
            # Check polling rate support
            if "polling_rate" in settings:
                result["capabilities"]["has_polling_rate"] = True
                poll_info = settings["polling_rate"]
                if "choices" in poll_info:
                    result["capabilities"]["polling_rates"] = list(poll_info["choices"].keys())
            
            # Check button mapping support
            if "buttons_mapping" in settings:
                result["capabilities"]["has_buttons"] = True
                btn_info = settings["buttons_mapping"]
                if "buttons" in btn_info:
                    buttons = list(btn_info["buttons"].keys())
                    # Filter to just buttonN entries
                    result["capabilities"]["buttons"] = [b for b in buttons if b.lower().startswith("button")]
        
        mouse.close()
        
    except Exception as e:
        result["error"] = str(e)
    
    return result


def cmd_get_battery() -> Dict[str, Any]:
    """Get current battery status."""
    result = {
        "supported": False,
        "level": 100,
        "is_charging": False,
        "error": ""
    }
    
    mouse = get_mouse()
    if mouse is None:
        result["error"] = "No mouse connected"
        return result
    
    try:
        battery_info = mouse.battery
        if battery_info:
            result["supported"] = True
            result["level"] = battery_info.get("level", 100) or 100
            result["is_charging"] = battery_info.get("is_charging", False) or False
        mouse.close()
    except Exception as e:
        result["error"] = str(e)
    
    return result


def cmd_set_sensitivity(presets: List[int]) -> Dict[str, Any]:
    """Set sensitivity/DPI presets."""
    result = {"success": False, "error": ""}
    
    mouse = get_mouse()
    if mouse is None:
        result["error"] = "No mouse connected"
        return result
    
    try:
        # The method is dynamically generated as set_<setting_name>
        # Newer mice use a combined "set_sensitivity"; older ones use "set_sensitivity1", etc.
        if hasattr(mouse, 'set_sensitivity'):
            mouse.set_sensitivity(presets)
            mouse.save()
            result["success"] = True
        else:
            # Try individual sensitivity1, sensitivity2, etc.
            profile_settings = mouse.mouse_profile.get("settings", {})
            any_set = False
            for i, dpi in enumerate(presets, start=1):
                setting_name = f"sensitivity{i}"
                if setting_name in profile_settings:
                    getattr(mouse, f"set_{setting_name}")(dpi)
                    any_set = True
            if any_set:
                mouse.save()
                result["success"] = True
            else:
                result["error"] = "Device does not support sensitivity adjustment"
        mouse.close()
    except Exception as e:
        result["error"] = str(e)
    
    return result


def cmd_set_polling_rate(rate: int) -> Dict[str, Any]:
    """Set polling rate in Hz."""
    result = {"success": False, "error": ""}
    
    mouse = get_mouse()
    if mouse is None:
        result["error"] = "No mouse connected"
        return result
    
    try:
        if hasattr(mouse, 'set_polling_rate'):
            mouse.set_polling_rate(rate)
            mouse.save()
            result["success"] = True
        else:
            result["error"] = "Device does not support polling rate adjustment"
        mouse.close()
    except Exception as e:
        result["error"] = str(e)
    
    return result


def cmd_set_buttons(mappings: Dict[str, str]) -> Dict[str, Any]:
    """Set button mappings."""
    result = {"success": False, "error": ""}
    
    # Map generic modifier names to rivalcfg format
    key_aliases = {
        "Shift": "LeftShift",
        "Ctrl": "LeftCtrl", 
        "Alt": "LeftAlt",
    }
    
    mouse = get_mouse()
    if mouse is None:
        result["error"] = "No mouse connected"
        return result
    
    try:
        # Check for unsupported key combinations
        for btn, action in mappings.items():
            if '+' in action:
                # rivalcfg doesn't support key combinations - only single keys
                result["error"] = f"Key combinations like '{action}' are not supported by rivalcfg. Only single keys are allowed."
                return result
        
        if hasattr(mouse, 'set_buttons_mapping'):
            # Build the buttons mapping string in rivalcfg format
            # Format: buttons(button1=action1; button2=action2; ...; layout=qwerty)
            mapping_parts = []
            for btn, action in mappings.items():
                # Convert Button1 -> button1 for the format string
                btn_lower = btn.lower()
                # Map generic modifier names to rivalcfg format
                mapped_action = key_aliases.get(action, action)
                mapping_parts.append(f"{btn_lower}={mapped_action}")
            
            # Add layout at the end
            mapping_parts.append("layout=qwerty")
            mapping_str = f"buttons({'; '.join(mapping_parts)})"
            mouse.set_buttons_mapping(mapping_str)
            mouse.save()
            result["success"] = True
        else:
            result["error"] = "Device does not support button mapping"
        mouse.close()
    except Exception as e:
        result["error"] = str(e)
    
    return result


def cmd_reset() -> Dict[str, Any]:
    """Reset all settings to factory defaults."""
    result = {"success": False, "error": ""}
    
    mouse = get_mouse()
    if mouse is None:
        result["error"] = "No mouse connected"
        return result
    
    try:
        mouse.reset_settings()
        mouse.save()
        result["success"] = True
        mouse.close()
    except Exception as e:
        result["error"] = str(e)
    
    return result


def parse_buttons_mapping(mapping_str: str) -> Dict[str, str]:
    """Parse a buttons mapping string like 'buttons(button1=button1; button9=LeftShift; layout=qwerty)'
    
    Only returns non-default bindings (where action != buttonN)
    Converts rivalcfg key names to generic UI names (e.g., LeftShift -> Shift)
    """
    # Map rivalcfg names back to generic UI names
    display_aliases = {
        "LeftShift": "Shift",
        "RightShift": "Shift", 
        "LeftCtrl": "Ctrl",
        "RightCtrl": "Ctrl",
        "LeftAlt": "Alt",
        # RightAlt stays as RightAlt since it's distinguishable
    }
    
    result = {}
    if not mapping_str or not mapping_str.startswith("buttons("):
        return result
    
    # Extract content between buttons( and )
    content = mapping_str[8:-1] if mapping_str.endswith(")") else mapping_str[8:]
    
    # Split by ; and parse each key=value pair
    for part in content.split(";"):
        part = part.strip()
        if "=" in part:
            key, value = part.split("=", 1)
            key = key.strip().lower()
            value = value.strip()
            
            # Skip layout and scroll entries
            if key == "layout" or key.startswith("scroll"):
                continue
                
            if key.startswith("button"):
                # Normalize button name to "Button1" format
                button_num = key.replace("button", "")
                normalized_key = f"Button{button_num}"
                
                # Only include non-default bindings
                # Default is buttonN=buttonN (e.g., button1=button1)
                # Also include if action is "dpi" or "disabled" for button6
                default_value = key  # e.g., "button1"
                if value.lower() != default_value and value.lower() != "disabled":
                    # Convert rivalcfg names to generic UI names
                    display_value = display_aliases.get(value, value)
                    result[normalized_key] = display_value
                elif value.lower() == "disabled" and key != "button7" and key != "button8" and key != "button9":
                    # button7/8/9 are disabled by default, so only include if it's a different button
                    result[normalized_key] = value
                elif key == "button6" and value.lower() != "dpi":
                    # button6 default is dpi, include if different
                    display_value = display_aliases.get(value, value)
                    result[normalized_key] = display_value
    
    return result


def cmd_get_settings() -> Dict[str, Any]:
    """Get current device settings from rivalcfg's saved config."""
    result = {
        "success": False,
        "error": "",
        "settings": {
            "sensitivity": [],
            "polling_rate": 1000,
            "buttons": {}
        }
    }
    
    mouse = get_mouse()
    if mouse is None:
        result["error"] = "No mouse connected"
        return result
    
    try:
        # Read settings using mouse_settings.get() method
        settings = mouse.mouse_settings
        
        # Get sensitivity - handle both combined "sensitivity" and individual "sensitivityN" keys
        try:
            sens = settings.get("sensitivity")
            if sens is not None:
                if isinstance(sens, (list, tuple)):
                    result["settings"]["sensitivity"] = [int(s) for s in sens]
                elif isinstance(sens, str):
                    # Parse comma-separated string like "400, 800, 1200"
                    result["settings"]["sensitivity"] = [int(s.strip()) for s in sens.split(",")]
                elif isinstance(sens, int):
                    result["settings"]["sensitivity"] = [sens]
        except (KeyError, TypeError, ValueError):
            pass
        
        # Fall back to sensitivity1/sensitivity2/... pattern (older mice)
        if not result["settings"]["sensitivity"]:
            presets = []
            for i in range(1, 6):  # Try sensitivity1 through sensitivity5
                try:
                    val = settings.get(f"sensitivity{i}")
                    if val is not None:
                        presets.append(int(val))
                except (KeyError, TypeError, ValueError):
                    break
            if presets:
                result["settings"]["sensitivity"] = presets
        
        # Get polling rate
        try:
            poll = settings.get("polling_rate")
            if poll is not None:
                result["settings"]["polling_rate"] = int(poll)
        except Exception:
            pass
        
        # Get button mappings - returns string like "buttons(button1=button1; ...)"
        try:
            buttons_str = settings.get("buttons_mapping")
            if buttons_str:
                result["settings"]["buttons"] = parse_buttons_mapping(buttons_str)
        except Exception:
            pass
        
        result["success"] = True
        mouse.close()
    except Exception as e:
        result["error"] = str(e)
    
    return result


def main():
    parser = argparse.ArgumentParser(
        description="RivalCfg Python wrapper for Quickshell",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")
    
    # Detect command
    subparsers.add_parser("detect", help="Detect connected SteelSeries mouse")
    
    # Battery command
    subparsers.add_parser("battery", help="Get battery status")
    
    # Sensitivity command
    sens_parser = subparsers.add_parser("sensitivity", help="Set sensitivity/DPI presets")
    sens_parser.add_argument("presets", type=str, help="Comma-separated DPI values (e.g., 800,1600,3200)")
    
    # Polling rate command
    poll_parser = subparsers.add_parser("polling-rate", help="Set polling rate")
    poll_parser.add_argument("rate", type=int, help="Polling rate in Hz")
    
    # Buttons command
    btn_parser = subparsers.add_parser("buttons", help="Set button mappings")
    btn_parser.add_argument("mappings", type=str, help="JSON object of button mappings")
    
    # Reset command
    subparsers.add_parser("reset", help="Reset to factory defaults")
    
    # Get settings command
    subparsers.add_parser("settings", help="Get current settings")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    result = {}
    
    if args.command == "detect":
        result = cmd_detect()
    elif args.command == "battery":
        result = cmd_get_battery()
    elif args.command == "sensitivity":
        presets = [int(x.strip()) for x in args.presets.split(",")]
        result = cmd_set_sensitivity(presets)
    elif args.command == "polling-rate":
        result = cmd_set_polling_rate(args.rate)
    elif args.command == "buttons":
        mappings = json.loads(args.mappings)
        result = cmd_set_buttons(mappings)
    elif args.command == "reset":
        result = cmd_reset()
    elif args.command == "settings":
        result = cmd_get_settings()
    
    # Output JSON result
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
