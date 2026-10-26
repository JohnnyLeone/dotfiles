#!/usr/bin/env python3
"""Stream AMD GPU utilization for ashell, without pinning a DRM card number."""
import json
import signal
import sys
import time
from pathlib import Path


def reading():
    values = []
    seen = set()
    for card in Path('/sys/class/drm').glob('card[0-9]*'):
        device = card / 'device'
        try:
            if device.resolve() in seen or (device / 'vendor').read_text().strip() != '0x1002':
                continue
            seen.add(device.resolve())
            values.append(max(0, min(100, int((device / 'gpu_busy_percent').read_text()))))
        except (OSError, ValueError):
            continue
    return {'text': f'GPU {max(values)}%' if values else '', 'alt': 'gpu' if values else 'unavailable'}


if __name__ == '__main__':
    # A closed bar subscription should also stop its helper.
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    while True:
        print(json.dumps(reading()), flush=True)
        if '--once' in sys.argv:
            break
        time.sleep(5)
