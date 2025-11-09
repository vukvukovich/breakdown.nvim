#!/usr/bin/env python3
import subprocess
import re

# Get all HID devices
result = subprocess.run(
    ['ioreg', '-l', '-w0', '-c', 'AppleHIDTransportInterface'],
    capture_output=True,
    text=True
)

# Find accelerometer section
lines = result.stdout.split('\n')
in_accel = False
props = {}

for i, line in enumerate(lines):
    if 'Accelerometer' in line and 'InterfaceName' not in line:
        in_accel = True
        print("Found Accelerometer device!")
        continue

    if in_accel:
        # Extract properties
        match = re.search(r'"(\w+)"\s*=\s*(.+)$', line)
        if match:
            key, value = match.groups()
            props[key] = value
            print(f"  {key}: {value}")

        # Stop at next device or closing brace
        if line.strip().startswith('+-o ') and 'Accelerometer' not in line:
            break

print("\nKey properties:")
for key in ['PrimaryUsagePage', 'PrimaryUsage', 'DeviceUsagePage', 'DeviceUsage']:
    if key in props:
        print(f"  {key}: {props[key]}")
