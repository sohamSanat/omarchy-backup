---
title: Argparse Help String Percent Escaping and Linux Sysfs Negative Current Parsing
category: CLI Robustness / Hardware Parsing
date: 2026-09-11
---

# Argparse Help String Percent Escaping and Linux Sysfs Negative Current Parsing

### 1. Python Argparse Percent Escaping with ArgumentDefaultsHelpFormatter
When configuring CLI arguments using `argparse.ArgumentParser` with `formatter_class=argparse.ArgumentDefaultsHelpFormatter`, help strings containing unescaped percentage signs (e.g., `help="Alert when battery reaches 100% full charge."`) cause `argparse` to crash during `_expand_help` with:
```text
TypeError: must be real number, not dict
ValueError: badly formed help string
```
`argparse` performs `%` formatting on help strings to interpolate variables like `%(default)s` and `%(prog)s`. An unescaped `% ` or `%f` is treated as a format specifier.
**Fix:** Always escape literal percentage signs as `%%`:
```python
parser.add_argument(
    "--alert-full",
    action="store_true",
    help="Send notification when battery reaches 100%% full charge.",
)
```

### 2. Linux Sysfs Battery Drivers Negative `current_now`
Under `/sys/class/power_supply/*/`, Linux ACPI and battery kernel drivers often represent discharging current as a negative microampere value (e.g. `POWER_SUPPLY_CURRENT_NOW=-1850000`).
Evaluating discharge conditions with `if current_now > 0:` evaluates to `False`, silently disabling `time_to_empty` calculation and leaving estimates as `None` or `N/A`.
**Fix:** Always normalize with `abs()` when checking and computing discharge rates:
```python
curr_ua = abs(current_now_ua) if current_now_ua is not None else None
if curr_ua is not None and curr_ua > 0:
    time_to_empty_secs = int((charge_now_uah / curr_ua) * 3600)
```
