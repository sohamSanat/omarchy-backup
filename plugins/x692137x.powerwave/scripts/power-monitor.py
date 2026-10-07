#!/usr/bin/env python3
"""
Power supply monitor for Omarchy PowerWave plugin.
Monitors kernel uevents via netlink socket and inspects /sys/class/power_supply
to reliably detect AC / USB-PD power connection events in real time.
"""

import os
import sys
import glob
import time
import select
import socket
import signal

def is_charging_active():
    """
    Check if the laptop is connected to external AC/USB-PD power or actively charging.
    Returns True if:
      - Any non-battery power supply (AC, USB, UCSI PD) is online (online == 1)
      - Any battery reports status 'Charging'
      - Any battery has positive current flow while not discharging
    """
    any_online_supply = False
    any_battery_charging = False

    for path in glob.glob("/sys/class/power_supply/*"):
        type_file = os.path.join(path, "type")
        online_file = os.path.join(path, "online")
        status_file = os.path.join(path, "status")
        current_file = os.path.join(path, "current_now")

        dev_type = ""
        if os.path.isfile(type_file):
            try:
                with open(type_file, "r") as f:
                    dev_type = f.read().strip().lower()
            except Exception:
                pass

        name = os.path.basename(path).lower()

        # Check online attribute (standard for AC, USB, and UCSI power supplies)
        if os.path.isfile(online_file):
            try:
                with open(online_file, "r") as f:
                    val = f.read().strip()
                    if val == "1":
                        # If it is a battery, online indicates presence, not external power
                        if dev_type != "battery" and not name.startswith("bat"):
                            any_online_supply = True
            except Exception:
                pass

        # Check battery status
        if os.path.isfile(status_file):
            try:
                with open(status_file, "r") as f:
                    status = f.read().strip().lower()
                    if status == "charging":
                        any_battery_charging = True
            except Exception:
                pass

        # Check if battery current is positive and not discharging
        if dev_type == "battery" and os.path.isfile(current_file):
            try:
                with open(current_file, "r") as f:
                    curr = int(f.read().strip())
                    if curr > 0 and not any_battery_charging:
                        # Verify status isn't discharging
                        if os.path.isfile(status_file):
                            with open(status_file, "r") as sf:
                                if sf.read().strip().lower() != "discharging":
                                    any_battery_charging = True
            except Exception:
                pass

    return any_online_supply or any_battery_charging

def main():
    # Ensure stdout is flushed immediately for line-by-line reading in QML
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(line_buffering=True)

    def handle_exit(signum, frame):
        sys.exit(0)

    signal.signal(signal.SIGTERM, handle_exit)
    signal.signal(signal.SIGINT, handle_exit)

    # Attempt to open Linux netlink socket for kernel kobject uevents
    nl_sock = None
    try:
        # NETLINK_KOBJECT_UEVENT = 15
        nl_sock = socket.socket(socket.AF_NETLINK, socket.SOCK_RAW, 15)
        # Bind: pid 0 (let kernel choose), multicast group 1 (kernel uevents)
        nl_sock.bind((0, 1))
        nl_sock.setblocking(False)
    except Exception as e:
        sys.stderr.write(f"[power-monitor] Netlink socket unavailable: {e}. Using polling fallback.\n")
        nl_sock = None

    # Initial state determination
    last_state = is_charging_active()
    # Output initial state as baseline (so plugin doesn't trigger on fresh launch)
    if last_state:
        print("STATE:CHARGING", flush=True)
    else:
        print("STATE:DISCHARGING", flush=True)

    # Event loop
    while True:
        try:
            if nl_sock is not None:
                # Wait for kernel netlink event or 0.5s safety timeout
                r, _, _ = select.select([nl_sock], [], [], 0.5)
                if r:
                    # Drain netlink socket
                    try:
                        while True:
                            data = nl_sock.recv(4096)
                            if not data:
                                break
                    except (BlockingIOError, InterruptedError):
                        pass
            else:
                time.sleep(0.5)

            current_state = is_charging_active()
            if current_state != last_state:
                last_state = current_state
                if current_state:
                    print("CHARGING", flush=True)
                else:
                    print("DISCHARGING", flush=True)

        except Exception as e:
            time.sleep(0.5)

if __name__ == "__main__":
    main()
