#!/usr/bin/python3

import subprocess
import sys
import dbus

DISCONNECT_LABEL = "disconnect"

def parse_locations(output):
    locations = []
    lines = output.splitlines()
    # Skip header line
    for line in lines[1:]:
        line = line.strip()
        if not line or line.startswith("You can connect"):
            continue
        # Columns are fixed-width: ISO(6), COUNTRY(21), CITY(31), PING
        parts = line.split()
        if len(parts) < 3:
            continue
        iso = parts[0]  # 2-char ISO code
        # Find where ping estimate is (last token, numeric)
        try:
            ping = int(parts[-1])
            # Everything between iso and ping is country + city
            # COUNTRY is 21 chars wide, CITY is 31 chars wide in the raw line
            country = line[6:27].strip()
            city = line[27:58].strip()
        except (ValueError, IndexError):
            continue
        if city:
            locations.append((city, country, ping))
    return locations

def notify(summary, body=""):
    bus = dbus.SessionBus()
    obj = bus.get_object("org.freedesktop.Notifications", "/org/freedesktop/Notifications")
    iface = dbus.Interface(obj, "org.freedesktop.Notifications")
    iface.Notify("select-vpn-location", 0, "network-vpn", summary, body, [], {}, 5000)

def is_connected():
    proc = subprocess.run(["vpn", "status"], capture_output=True, text=True)
    return proc.stdout.startswith("Connected")

def main():
    # Get list of VPN locations
    try:
        proc = subprocess.run(["vpn", "list-locations"], check=True, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        print(f'vpn list-locations failed with error {e.returncode}: {e.stderr}')
        sys.exit(e.returncode)

    locations = parse_locations(proc.stdout)

    # Build wofi menu: "city\tcountry — ping ms" so we display full info but key on city
    menu_lines = [DISCONNECT_LABEL] if is_connected() else []
    for city, country, ping in locations:
        menu_lines.append(f"{city}\t{country} — {ping}ms")

    wofi_input = "\n".join(menu_lines) + "\n"

    try:
        wofi_proc = subprocess.run(["wofi", "--show=dmenu"], check=True, text=True, input=wofi_input, capture_output=True)
    except subprocess.CalledProcessError as e:
        sys.exit(e.returncode)

    selected = wofi_proc.stdout.strip()

    if selected == DISCONNECT_LABEL:
        subprocess.run(["vpn", "disconnect"])
    else:
        # Extract city name (before the tab)
        city = selected.split("\t")[0]
        result = subprocess.run(["vpn", "connect", "-l", city], capture_output=True, text=True)
        if result.returncode != 0:
            notify("VPN connection failed", f"Could not connect to {city}")

if __name__ == "__main__":
    main()
