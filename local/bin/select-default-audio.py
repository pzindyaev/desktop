#!/usr/bin/python3

import subprocess
import sys
import json
import getopt

def main(args):
    # Parse command line arguments
    try:
        opts, _ = getopt.getopt(args[1:], "hico", ["help", "input", "output", "camera"])
    except getopt.GetoptError as err:
        print(str(err))
        sys.exit(2)

    media_class = "Audio/Sink"
    for opt, _ in opts:
        if opt in ("-i", "--input"):
            media_class = "Audio/Source"
        elif opt in ("-o", "--output"):
            media_class = "Audio/Sink"
        elif opt in ("-c", "--camera"):
            media_class = "Video/Source"
        elif opt in ("-h", "--help"):
            print(f'''Usage: python3 {args[0]} [argument]
list of arguments:
    -i | --input : Set the default input
    -o | --output : Ser the default output
    -c | --camera : Set the default camera
    -h : Display this help''')
            sys.exit()

    # Run pw-dump to get the devices
    try:
        pw_proccess = subprocess.run(["pw-dump"], check=True, capture_output=True)
    except subprocess.CalledProcessError as e:
        print(f'pw-dump failed with error {e.returncode}: {e.stderr}')
        sys.exit(e.returncode)

    # Parse json output of the pw-dump
    pw_devices = ""
    pw_data = json.loads(pw_proccess.stdout)
    for item in pw_data:
        if item['type'] == "PipeWire:Interface:Node" \
            and 'info' in item \
            and 'props' in item['info'] \
            and 'media.class' in item['info']['props'] \
            and item['info']['props']['media.class'] == media_class: 

            pw_devices += f"{item['id']}:{item['info']['props']['node.description']}\n" 

    # Run wofi to select the device
    try:
        wofi_proccess = subprocess.run(["wofi", "--show=dmenu"], check=True, text=True, input=pw_devices, capture_output=True)
    except subprocess.CalledProcessError as e:
        sys.exit(e.returncode)

    # Set selected device as the default
    wofi_selected_device = wofi_proccess.stdout.split(":")
    try:
        subprocess.run(["wpctl", "set-default", f"{wofi_selected_device[0]}"])
    except subprocess.CalledProcessError as e:
        sys.exit(e.returncode)

if __name__ == "__main__":
    main(sys.argv)
