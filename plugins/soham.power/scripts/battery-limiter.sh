#!/usr/bin/env bash

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy"
CONFIG_FILE="$CONFIG_DIR/battery-limiter.json"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy"
STATE_FILE="$STATE_DIR/battery-limiter.state"
POWER_SUPPLY_PATH="${OMARCHY_POWER_SUPPLY_PATH:-/sys/class/power_supply}"

mkdir -p "$CONFIG_DIR" "$STATE_DIR"

detect_sysfs_node() {
  local node=""
  # 1. Standard kernel interface
  for f in "$POWER_SUPPLY_PATH"/BAT*/charge_control_end_threshold; do
    if [[ -f "$f" ]]; then node="$f"; break; fi
  done
  if [[ -n "$node" ]]; then echo "$node"; return 0; fi

  # 2. Alternative thinkpad/kernel interface
  for f in "$POWER_SUPPLY_PATH"/BAT*/charge_stop_threshold; do
    if [[ -f "$f" ]]; then node="$f"; break; fi
  done
  if [[ -n "$node" ]]; then echo "$node"; return 0; fi

  # 3. ASUS
  if [[ -f "/sys/devices/platform/asus-nb-wmi/charge_control_end_threshold" ]]; then
    echo "/sys/devices/platform/asus-nb-wmi/charge_control_end_threshold"
    return 0
  fi
  if [[ -f "/sys/module/asus_wmi/parameters/battery_charge_limit" ]]; then
    echo "/sys/module/asus_wmi/parameters/battery_charge_limit"
    return 0
  fi

  # 4. Lenovo IdeaPad conservation mode (binary toggle: 1=~60%, 0=100%)
  for f in /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode /sys/bus/platform/drivers/ideapad_laptop/*/conservation_mode; do
    if [[ -f "$f" ]]; then echo "$f"; return 0; fi
  done

  # 5. LG Laptop
  if [[ -f "/sys/devices/platform/lg-laptop/battery_care_limit" ]]; then
    echo "/sys/devices/platform/lg-laptop/battery_care_limit"
    return 0
  fi

  # 6. Samsung
  if [[ -f "/sys/devices/platform/samsung/battery_life_extender" ]]; then
    echo "/sys/devices/platform/samsung/battery_life_extender"
    return 0
  fi

  # 7. Sony
  if [[ -f "/sys/devices/platform/sony-laptop/battery_care_limiter" ]]; then
    echo "/sys/devices/platform/sony-laptop/battery_care_limiter"
    return 0
  fi

  # 8. Huawei
  if [[ -f "/sys/devices/platform/huawei-wmi/charge_thresholds" ]]; then
    echo "/sys/devices/platform/huawei-wmi/charge_thresholds"
    return 0
  fi

  return 1
}

read_sysfs_limit() {
  local node
  node=$(detect_sysfs_node 2>/dev/null || true)
  if [[ -n "$node" && -r "$node" ]]; then
    local val
    val=$(<"$node")
    if [[ "$node" == *"conservation_mode"* || "$node" == *"battery_life_extender"* ]]; then
      if [[ "$val" == "1" ]]; then echo "60"; return 0; else echo "100"; return 0; fi
    fi
    echo "$val"
    return 0
  fi
  return 1
}

get_configured_limit() {
  local sysfs_val
  sysfs_val=$(read_sysfs_limit 2>/dev/null || true)
  if [[ -n "$sysfs_val" && "$sysfs_val" =~ ^[0-9]+$ ]]; then
    echo "$sysfs_val"
    return 0
  fi

  if [[ -f "$CONFIG_FILE" ]]; then
    local cfg_val
    cfg_val=$(jq -r '.limit // empty' "$CONFIG_FILE" 2>/dev/null || true)
    if [[ -n "$cfg_val" && "$cfg_val" =~ ^[0-9]+$ ]]; then
      echo "$cfg_val"
      return 0
    fi
  fi

  # Default to 80% (standard balanced longevity threshold)
  echo "80"
}

cmd_get() {
  local limit
  limit=$(get_configured_limit)
  local node
  node=$(detect_sysfs_node 2>/dev/null || true)
  local hw_supported="false"
  if [[ -n "$node" ]]; then
    hw_supported="true"
  fi

  # Battery health & UPower data
  local battery
  battery=$(upower -e 2>/dev/null | grep BAT | head -n 1 || true)
  local health="—"
  local health_detail=""
  local energy_full=""
  local energy_design=""
  local cycles="—"

  if [[ -n "$battery" ]]; then
    local battery_info
    battery_info=$(upower -i "$battery" 2>/dev/null || true)
    local cap
    cap=$(awk '/capacity:/ { print int($2); exit }' <<<"$battery_info" || true)
    energy_full=$(awk '/energy-full:/ { printf "%.1f", $2; exit }' <<<"$battery_info" || true)
    energy_design=$(awk '/energy-full-design:/ { printf "%.1f", $2; exit }' <<<"$battery_info" || true)

    if [[ -n "$cap" && "$cap" != "0" ]]; then
      health="${cap}%"
    elif [[ -n "$energy_full" && -n "$energy_design" && "$energy_design" != "0.0" ]]; then
      health=$(awk -v f="$energy_full" -v d="$energy_design" 'BEGIN { printf "%d%%", (f/d)*100 }')
    fi

    if [[ -n "$energy_full" && -n "$energy_design" && "$energy_design" != "0.0" ]]; then
      health_detail="${energy_full} / ${energy_design} Wh"
    fi

    cycles=$(cat "$POWER_SUPPLY_PATH"/BAT*/cycle_count 2>/dev/null | head -1 || true)
    [[ -z "$cycles" ]] && cycles=$(awk '/charge-cycles:/ { print $2; exit }' <<<"$battery_info" || true)
    [[ -z "$cycles" || "$cycles" == "N/A" || "$cycles" == "-1" ]] && cycles="—"
  fi

  if [[ "${1:-}" == "--json" ]]; then
    jq -n \
      --arg limit "$limit" \
      --arg hw "$hw_supported" \
      --arg node "$node" \
      --arg health "$health" \
      --arg healthDetail "$health_detail" \
      --arg cycles "$cycles" \
      '{limit: ($limit | tonumber), hardwareSupported: ($hw == "true"), sysfsNode: $node, health: $health, healthDetail: $healthDetail, cycles: $cycles}'
  else
    printf 'limit\t%s\n' "$limit"
    printf 'hardware_supported\t%s\n' "$hw_supported"
    printf 'sysfs_node\t%s\n' "$node"
    printf 'health\t%s\n' "$health"
    printf 'health_detail\t%s\n' "$health_detail"
    printf 'cycles\t%s\n' "$cycles"
  fi
}

cmd_set() {
  local target="${1:-}"
  if [[ -z "$target" || ! "$target" =~ ^[0-9]+$ || "$target" -lt 40 || "$target" -gt 100 ]]; then
    echo "Error: Target limit must be an integer between 40 and 100 (got: '$target')" >&2
    exit 1
  fi

  local node
  node=$(detect_sysfs_node 2>/dev/null || true)
  local hw_supported="false"

  if [[ -n "$node" ]]; then
    hw_supported="true"
    # Construct script to apply sysfs and persist in /etc/tmpfiles.d
    local apply_cmd=""
    if [[ "$node" == *"conservation_mode"* || "$node" == *"battery_life_extender"* ]]; then
      local bit=$([[ "$target" -le 80 ]] && echo 1 || echo 0)
      apply_cmd="echo '$bit' > '$node' && mkdir -p /etc/tmpfiles.d && echo 'w $node - - - - $bit' > /etc/tmpfiles.d/battery-limiter.conf"
    elif [[ "$node" == *"huawei-wmi/charge_thresholds"* ]]; then
      local start_thresh=$(( target > 60 ? target - 5 : target ))
      apply_cmd="echo '$start_thresh $target' > '$node' && mkdir -p /etc/tmpfiles.d && echo 'w $node - - - - $start_thresh $target' > /etc/tmpfiles.d/battery-limiter.conf"
    else
      # Standard sysfs threshold
      local start_node="${node%_end_threshold}_start_threshold"
      if [[ -f "$start_node" && "$target" -lt 100 ]]; then
        local start_thresh=$(( target > 5 ? target - 5 : target ))
        apply_cmd="echo '$target' > '$node' && echo '$start_thresh' > '$start_node' && mkdir -p /etc/tmpfiles.d && echo 'w $node - - - - $target' > /etc/tmpfiles.d/battery-limiter.conf && echo 'w $start_node - - - - $start_thresh' >> /etc/tmpfiles.d/battery-limiter.conf"
      else
        apply_cmd="echo '$target' > '$node' && mkdir -p /etc/tmpfiles.d && echo 'w $node - - - - $target' > /etc/tmpfiles.d/battery-limiter.conf"
      fi
    fi

    # Check if already writable directly, else elevate with pkexec
    if [[ -w "$node" ]]; then
      bash -c "$apply_cmd" || true
    else
      pkexec bash -c "$apply_cmd" || {
        echo "Warning: Polkit elevation cancelled or failed. Limit saved in user preferences." >&2
      }
    fi
  fi

  # Save to user config
  jq -n \
    --argjson limit "$target" \
    --arg hw "$hw_supported" \
    --arg node "$node" \
    --arg updated "$(date -Iseconds)" \
    '{limit: $limit, hardwareSupported: ($hw == "true"), sysfsNode: $node, updatedAt: $updated}' \
    > "$CONFIG_FILE"

  # Reset state notification tracker
  echo "0" > "$STATE_FILE"

  if [[ "$hw_supported" == "true" ]]; then
    if command -v omarchy-notification-send >/dev/null 2>&1; then
      omarchy-notification-send -g "󰂄" "Battery Limit Set" "Hardware charging threshold set to ${target}%${preset_label}"
    fi
    echo "Battery limit set to ${target}%"
  else
    if command -v omarchy-notification-send >/dev/null 2>&1; then
      omarchy-notification-send -g "󰂄" "Battery Alert Set" "Alert threshold set to ${target}%${preset_label} (Hardware limit unsupported on this laptop model)"
    fi
    echo "Battery alert set to ${target}% (Notification alert mode)"
  fi
}

cmd_check() {
  local limit
  limit=$(get_configured_limit)
  if [[ "$limit" -ge 100 ]]; then
    exit 0
  fi

  local battery
  battery=$(upower -e 2>/dev/null | grep BAT | head -n 1 || true)
  [[ -z "$battery" ]] && exit 0

  local battery_info
  battery_info=$(upower -i "$battery" 2>/dev/null || true)
  local percentage
  percentage=$(awk '/percentage:/ { print int($2); exit }' <<<"$battery_info" || true)
  local state
  state=$(awk '/state:/ { print $2; exit }' <<<"$battery_info" || true)

  local on_battery=false
  if [[ $(busctl get-property org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.UPower OnBattery 2>/dev/null) == "b true" ]]; then
    on_battery=true
  fi

  if [[ "$on_battery" == "true" ]]; then
    # Reset notified state when unplugged
    echo "0" > "$STATE_FILE"
    exit 0
  fi

  local last_notified=0
  if [[ -f "$STATE_FILE" ]]; then
    last_notified=$(<"$STATE_FILE")
  fi

  local now
  now=$(date +%s)

  # If charging on AC and percentage >= limit
  if [[ "$percentage" -ge "$limit" && "$state" == "charging" ]]; then
    # Only notify every 30 minutes if still plugged in and charging
    if (( now - last_notified > 1800 )); then
      echo "$now" > "$STATE_FILE"
      if command -v omarchy-notification-send >/dev/null 2>&1; then
        omarchy-notification-send -u normal -g "󰂃" \
          "Battery Limit Reached (${limit}%)" \
          "Battery is currently at ${percentage}%. Unplug power adapter to preserve battery health."
      fi
    fi
  fi
}

case "${1:-get}" in
  get)
    shift || true
    cmd_get "$@"
    ;;
  set)
    shift
    cmd_set "$@"
    ;;
  check)
    shift
    cmd_check "$@"
    ;;
  help|--help|-h)
    echo "Usage: battery-limiter.sh [get [--json] | set <percentage> | check]"
    ;;
  *)
    echo "Unknown command: $1" >&2
    exit 1
    ;;
esac
