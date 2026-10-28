"""Verify display routing, idle coordination, and brightness limits without hardware."""
import importlib.machinery
import importlib.util
import fcntl
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.dont_write_bytecode = True
loader = importlib.machinery.SourceFileLoader('oled', str(ROOT / 'bin/dotfiles-oled'))
spec = importlib.util.spec_from_loader(loader.name, loader)
oled = importlib.util.module_from_spec(spec)
loader.exec_module(oled)


class Brightness(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='dotfiles-brightness-')
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        self.bin = self.work / 'bin'
        self.bin.mkdir()
        self.env = dict(os.environ, PATH=f'{self.bin}:{os.environ["PATH"]}',
                        XDG_RUNTIME_DIR=str(self.work), BRIGHTNESS_TEST=str(self.work))
        self.calls = self.work / 'calls'
        for name in ('hyprctl', 'dotfiles-oled', 'brightnessctl'):
            executable = self.bin / name
            executable.write_text('''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
root = Path(os.environ['BRIGHTNESS_TEST'])
name = Path(sys.argv[0]).name
if name == 'hyprctl':
    if (root / 'query-failure').exists(): sys.exit(1)
    print((root / 'monitors').read_text())
else:
    with (root / 'calls').open('a') as f:
        f.write(json.dumps([name, *sys.argv[1:]])+'\\n')
    if (root / 'control-failure').exists(): sys.exit(1)
''')
            executable.chmod(0o755)

    def route(self, monitors, action='up', success=True):
        (self.work / 'monitors').write_text(json.dumps(monitors))
        result = subprocess.run([str(ROOT / 'bin/dotfiles-brightness'), action],
                                env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode == 0, success, result.stderr)
        return [json.loads(line) for line in self.calls.read_text().splitlines()] if self.calls.exists() else []

    def test_external_oled_takes_priority_over_internal(self):
        calls = self.route([{'model': 'PG32UCDM3', 'name': 'DP-1'}, {'name': 'eDP-1'}])
        self.assertEqual(calls, [['dotfiles-oled', 'up']])

    def test_internal_only_uses_backlight_class(self):
        calls = self.route([{'name': 'eDP-1'}, {'model': 'PG32UCDM3', 'disabled': True}], 'down')
        self.assertEqual(calls, [['brightnessctl', '--class', 'backlight', '-e4', '-n2', 'set', '5%-']])

    def test_failed_display_query_does_not_touch_any_brightness(self):
        (self.work / 'query-failure').touch()
        self.assertEqual(self.route([], success=False), [])

    def test_unknown_display_does_not_touch_inactive_panel(self):
        self.assertEqual(self.route([{'name': 'HDMI-A-1', 'model': 'Other'}], success=False), [])

    def test_failed_ddc_does_not_fall_back_to_internal(self):
        (self.work / 'control-failure').touch()
        calls = self.route([{'model': 'PG32UCDM3'}, {'name': 'eDP-1'}], success=False)
        self.assertEqual(calls, [['dotfiles-oled', 'up']])

    def test_overlapping_key_repeat_is_dropped(self):
        runtime = self.work / 'dotfiles'
        runtime.mkdir()
        with (runtime / 'brightness-key.lock').open('a') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            self.assertEqual(self.route([{'model': 'PG32UCDM3'}]), [])

    def test_idle_restore_and_manual_adjustment_share_state(self):
        panel = {'value': 70}

        def ddc(*args):
            if args[0] == 'getvcp':
                return f"VCP 10 C {panel['value']} 100\n"
            panel['value'] = int(args[2])
            return ''

        with patch.dict(os.environ, self.env), patch.object(oled, 'ddc', ddc):
            oled.main('idle-dim')
            self.assertEqual(panel['value'], 50)
            oled.main('idle-dim')
            self.assertEqual(panel['value'], 50)
            oled.main('idle-resume')
            self.assertEqual(panel['value'], 70)
            oled.main('idle-dim')
            oled.main('up')
            self.assertEqual(panel['value'], 75)
            oled.main('idle-resume')
            self.assertEqual(panel['value'], 75)
            panel['value'] = 1
            oled.main('down')
            self.assertEqual(panel['value'], 1)
            panel['value'] = 99
            oled.main('up')
            self.assertEqual(panel['value'], 100)


if __name__ == '__main__':
    unittest.main()
