#!/usr/bin/env python3
"""Install individual files, with a reversible backup journal. No root changes."""
import argparse
import json
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FILES = [
    '.zshrc', '.aliases', '.functions', '.exports', '.path', '.dockerfunc',
    '.inputrc', '.tmux.conf', '.vimrc', '.gitconfig',
    '.config/nvim/init.vim', '.config/kitty/kitty.conf',
    '.config/hypr/hyprland.lua', '.config/hypr/hyprlock.conf',
    '.config/hypr/hypridle.conf', '.config/ashell/config.toml', '.config/ashell/gpu.py',
    '.config/vicinae/settings.json', '.config/gtk-3.0/settings.ini',
    '.config/gtk-4.0/settings.ini', '.gtkrc-2.0',
    '.config/qt5ct/qt5ct.conf', '.config/qt6ct/qt6ct.conf',
    '.config/pipewire/pipewire.conf.d/51-ui24r-aux01.conf',
    '.config/pipewire/pipewire.conf.d/52-ui24r-mic01.conf',
    '.config/pipewire/pipewire.conf.d/53-ui24r-aux23.conf',
    '.config/pipewire/pipewire.conf.d/54-ui24r-aux45.conf',
    '.config/pipewire/pipewire.conf.d/raop-discover.conf',
    '.config/uwsm/env', '.config/uwsm/env-hyprland',
    '.config/systemd/user/ashell.service.d/uwsm.conf',
    '.config/systemd/user/vicinae.service.d/uwsm.conf',
    '.config/systemd/user/hypridle.service.d/uwsm.conf',
    '.config/systemd/user/udiskie.service',
    '.local/share/dbus-1/services/org.freedesktop.Notifications.service',
]
BINS = [
    'dotfiles-hypr', 'dotfiles-bar', 'dotfiles-oled', 'dotfiles-brightness', 'dotfiles-app',
    'check-kconfig', 'cleanup-non-running-images',
    'createvm', 'gitdate', 'keyboard-backlight', 'keysign', 'openprs', 'passmenu',
    'update-mirrors', 'updateforks',
]
LINKS = [(name, name) for name in FILES] + [
    ('gitignore', '.gitignore'),
] + [(f'bin/{name}', f'.local/bin/{name}') for name in BINS]
OPTIONAL_LINKS = [(name, name) for name in ('.gnupg/gpg.conf', '.gnupg/gpg-agent.conf')]


def present(path):
    return path.exists() or path.is_symlink()


def same_link(path, source):
    return path.is_symlink() and path.resolve() == source.resolve()


def restore(backup):
    manifest = backup / 'manifest.json'
    data = json.loads(manifest.read_text())
    if data.get('restored'):
        print('This backup has already been restored.')
        return
    home = Path(data['home'])
    # Refuse before touching anything if a deployed file has since been replaced.
    for row in data['links']:
        dest = home / row['dest']
        if present(dest) and not same_link(dest, Path(row['source'])):
            raise RuntimeError(f'Refusing to replace a changed file: {dest}')
    for row in reversed(data['links']):
        dest = home / row['dest']
        if dest.is_symlink():
            dest.unlink()
        saved = backup / 'files' / row['dest']
        if present(saved):
            saved.rename(dest)
    data['restored'] = True
    manifest.write_text(json.dumps(data, indent=2) + '\n')
    print(f'Restored files from {backup}')


def install(home, dry_run=False, only=None):
    plan = []
    for src, name in LINKS + (OPTIONAL_LINKS if only is not None else []):
        if only is not None and name not in only:
            continue
        source, dest = ROOT / src, home / name
        if not source.is_file():
            raise RuntimeError(f'Missing source: {source}')
        if same_link(dest, source):
            continue
        # Never move or replace a configuration directory as a unit.
        if dest.is_dir() and not dest.is_symlink():
            raise RuntimeError(f'Expected a file, found a directory: {dest}')
        plan.append((source, dest, name))
    for source, dest, _ in plan:
        print(f'{"BACKUP + LINK" if present(dest) else "LINK"} {dest} -> {source}')
    if not plan:
        print('All dotfiles are already linked.')
    if dry_run or not plan:
        return
    backup = home / '.local/state/dotfiles/backups' / datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup.mkdir(parents=True, mode=0o700)
    manifest = backup / 'manifest.json'
    data = {'home': str(home), 'links': []}
    manifest.write_text(json.dumps(data, indent=2) + '\n')
    try:
        for source, dest, name in plan:
            if name.startswith('.gnupg/'):
                (home / '.gnupg').mkdir(mode=0o700, exist_ok=True)
            dest.parent.mkdir(parents=True, exist_ok=True)
            if present(dest):
                saved = backup / 'files' / name
                saved.parent.mkdir(parents=True, exist_ok=True)
                dest.rename(saved)
            data['links'].append({'dest': name, 'source': str(source)})
            manifest.write_text(json.dumps(data, indent=2) + '\n')
            dest.symlink_to(source)
    except Exception:
        restore(backup)
        raise
    print(f'Backup: {backup}')
    print(f'Undo: python3 {ROOT}/scripts/dotfiles.py restore {backup}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    setup = sub.add_parser('install')
    setup.add_argument('--home', type=Path, default=Path.home())
    setup.add_argument('--dry-run', action='store_true')
    setup.add_argument('--only', action='append', choices=[dest for _, dest in LINKS + OPTIONAL_LINKS],
                       help='Install only this relative destination; repeat to select more files')
    undo = sub.add_parser('restore')
    undo.add_argument('backup', type=Path)
    args = parser.parse_args()
    try:
        if args.command == 'install':
            install(args.home.expanduser().absolute(), args.dry_run, args.only)
        else:
            restore(args.backup.expanduser().absolute())
    except (OSError, RuntimeError, ValueError) as error:
        parser.exit(1, f'{error}\n')


if __name__ == '__main__':
    main()
