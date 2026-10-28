"""Check utility safety and portability without network calls or system changes."""
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class Tools(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='dotfiles-tools-')
        self.addCleanup(self.temporary.cleanup)
        self.work = Path(self.temporary.name)
        self.fakebin = self.work / 'bin'
        self.fakebin.mkdir()
        self.trace = self.work / 'calls.jsonl'
        self.env = dict(os.environ, PATH=f'{self.fakebin}:{os.environ["PATH"]}',
                        HOME=str(self.work), XDG_DATA_HOME=str(self.work / 'data'),
                        TOOL_TRACE=str(self.trace), WAYLAND_DISPLAY='test-wayland')

    def fake(self, name, body):
        path = self.fakebin / name
        path.write_text('#!/usr/bin/env python3\nimport json, os, sys\n'
                        'with open(os.environ["TOOL_TRACE"], "a") as f:\n'
                        '    f.write(json.dumps([os.path.basename(sys.argv[0]), *sys.argv[1:]]) + "\\n")\n'
                        + body + '\n')
        path.chmod(0o755)

    def calls(self):
        return [json.loads(line) for line in self.trace.read_text().splitlines()] if self.trace.exists() else []

    def run_tool(self, name, *args, success=True):
        result = subprocess.run([str(ROOT / 'bin' / name), *map(str, args)], env=self.env,
                                cwd=self.work, text=True, capture_output=True)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def test_help_never_runs_optional_tools(self):
        for name in ('check-kconfig', 'cleanup-non-running-images', 'createvm', 'gitdate',
                     'keyboard-backlight', 'keysign', 'openprs', 'passmenu', 'update-mirrors', 'updateforks'):
            self.assertIn('Usage:', self.run_tool(name, '--help').stdout)
        self.assertEqual(self.calls(), [])

    def test_forks_are_read_only_until_apply_and_never_force(self):
        self.fake('gh', 'if sys.argv[1:3] == ["repo", "list"]: print("demo/one\\ndemo/two")')
        self.env['GITHUB_USERNAME'] = 'another-default'
        self.run_tool('updateforks', 'demo')
        self.assertTrue(all(call[1:3] == ['repo', 'list'] for call in self.calls()))
        self.run_tool('updateforks', 'demo', '--apply')
        syncs = [call for call in self.calls() if call[1:3] == ['repo', 'sync']]
        self.assertEqual([call[3] for call in syncs], ['demo/one', 'demo/two'])
        self.assertFalse(any('--force' in call for call in self.calls()))

    def test_container_preview_and_conservative_pruning(self):
        self.fake('docker', 'print("test output")')
        self.run_tool('cleanup-non-running-images')
        self.assertEqual(self.calls(), [['docker', 'system', 'df']])
        self.run_tool('cleanup-non-running-images', '--apply')
        self.assertEqual(self.calls()[-1], ['docker', 'image', 'prune', '--all'])
        self.assertFalse(any('--force' in call or '-f' in call for call in self.calls()))

    def test_vm_preview_writes_nothing_and_apply_uses_user_session(self):
        self.fake('virt-install', '')
        iso = self.work / 'installer with spaces.iso'
        iso.touch()
        preview = self.run_tool('createvm', 'demo', iso)
        self.assertIn('qemu:///session', preview.stdout)
        self.assertFalse((self.work / 'data').exists())
        self.assertEqual(self.calls(), [])
        self.run_tool('createvm', 'demo', iso, '--apply')
        self.assertEqual(len(self.calls()), 1)
        self.assertIn('qemu:///session', self.calls()[0])
        # A failed rerun must not overwrite an existing disk.
        disk = self.work / 'data/libvirt/images/demo.qcow2'
        disk.write_text('existing disk')
        result = self.run_tool('createvm', 'demo', iso, '--apply', success=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(disk.read_text(), 'existing disk')
        self.assertEqual(len(self.calls()), 1)

    def test_pass_selection_types_only_first_line_without_argument_leak(self):
        store = self.work / '.password-store/work'
        store.mkdir(parents=True)
        (store / 'service.gpg').touch()
        self.fake('vicinae', 'sys.stdin.read(); print("work/service")')
        self.fake('pass', 'if "--clip" not in sys.argv: print("fake-secret\\nprivate notes")')
        self.fake('wtype', 'open(os.path.join(os.environ["HOME"], "typed"), "w").write(sys.stdin.read())')
        result = self.run_tool('passmenu', '--type')
        self.assertEqual((self.work / 'typed').read_text(), 'fake-secret')
        self.assertNotIn('fake-secret', result.stdout + result.stderr + self.trace.read_text())
        self.fake('vicinae', 'sys.exit(1)')
        before = len([call for call in self.calls() if call[0] == 'pass'])
        self.run_tool('passmenu')
        self.assertEqual(len([call for call in self.calls() if call[0] == 'pass']), before)

    def test_gitdate_preserves_instant_across_calendar_and_timezone_boundary(self):
        instant = '2020-01-01 00:15:00 +0530'
        for shell in ('bash', 'zsh'):
            result = subprocess.run([shell, '-c',
                                     'source "$1" "$2"; printf "%s\\n%s\\n" "$GIT_AUTHOR_DATE" "$GIT_COMMITTER_DATE"',
                                     'check', str(ROOT / 'bin/gitdate'), instant],
                                    env=self.env, text=True, capture_output=True, check=True)
            self.assertEqual(result.stdout.splitlines(), ['Tue, 31 Dec 2019 18:45:00 +0000'] * 2)

    def test_mirror_preview_performs_no_fetch_or_push(self):
        mirrors = self.work / 'mirrors'
        repo = mirrors / 'example.git'
        repo.mkdir(parents=True)
        self.fake('git', '''
args = sys.argv[1:]
if "remote.origin.mirror" in args: print("true")
elif "remote.origin.pushurl" in args: print("https://example.invalid/destination.git")
elif "get-url" in args: print("https://example.invalid/source.git")
''')
        self.run_tool('update-mirrors', mirrors)
        self.assertFalse(any('fetch' in call or 'push' in call for call in self.calls()))

    def test_kernel_query_matches_complete_flag_names(self):
        config = self.work / 'kernel.config'
        config.write_text('CONFIG_FOO_EXTRA=y\nCONFIG_BAR=m\n')
        self.run_tool('check-kconfig', config, '--flag', 'CONFIG_BAR')
        missing = self.run_tool('check-kconfig', config, '--flag', 'FOO', success=False)
        self.assertNotEqual(missing.returncode, 0, 'A similarly named flag was mistaken for the requested one')

    def test_app_launcher_preserves_arguments_in_plain_and_managed_sessions(self):
        self.fake('test-app', '')
        self.fake('uwsm', '')
        self.env.pop('DOTFILES_UWSM_SESSION', None)
        self.run_tool('dotfiles-app', 'test-app', 'argument with spaces', '--literal=$HOME')
        self.assertEqual(self.calls(), [['test-app', 'argument with spaces', '--literal=$HOME']])
        self.env['DOTFILES_UWSM_SESSION'] = '1'
        self.run_tool('dotfiles-app', 'test-app', 'argument with spaces', '--literal=$HOME')
        self.assertEqual(self.calls()[-1],
                         ['uwsm', 'app', '--', 'test-app', 'argument with spaces', '--literal=$HOME'])

    def test_managed_logout_closes_apps_then_stops_session(self):
        self.fake('uwsm', '')
        self.fake('hyprshutdown', '')
        self.env['DOTFILES_UWSM_SESSION'] = '1'
        self.run_tool('dotfiles-hypr', 'exit')
        self.assertEqual(self.calls(), [['hyprshutdown', '--no-exit', '--no-fork'], ['uwsm', 'stop']])
        self.env.pop('DOTFILES_UWSM_SESSION')
        self.run_tool('dotfiles-hypr', 'exit')
        self.assertEqual(self.calls()[-1], ['hyprshutdown'])

    def test_failed_graceful_shutdown_does_not_force_logout(self):
        self.fake('uwsm', '')
        self.fake('hyprshutdown', 'sys.exit(1)')
        self.env['DOTFILES_UWSM_SESSION'] = '1'
        result = self.run_tool('dotfiles-hypr', 'exit', success=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), [['hyprshutdown', '--no-exit', '--no-fork']])


if __name__ == '__main__':
    unittest.main(verbosity=1)
