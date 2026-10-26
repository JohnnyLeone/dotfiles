"""Exercise installer backup, idempotence, and safe restoration in a temporary home."""
import contextlib
import io
import tempfile
from pathlib import Path
from dotfiles import install, restore

with tempfile.TemporaryDirectory(prefix='dotfiles-test-') as directory:
    home = Path(directory)
    (home / '.config/hypr').mkdir(parents=True)
    (home / '.config/unrelated').mkdir()
    (home / '.config/unrelated/settings').write_text('keep me')
    (home / '.config/hypr/hyprland.lua').write_text('original desktop')
    (home / '.config/hypr/hyprland.conf').write_text('legacy fallback')
    (home / '.zshrc').symlink_to(home / 'missing-old-config')
    with contextlib.redirect_stdout(io.StringIO()):
        install(home, dry_run=True)
        assert not (home / '.local').exists(), 'Dry run wrote files'
        install(home)
        backup = next((home / '.local/state/dotfiles/backups').iterdir())
        assert (backup / 'files/.zshrc').is_symlink(), 'Lost original symlink'
        assert (backup / 'files/.config/hypr/hyprland.lua').read_text() == 'original desktop'
        install(home)
        assert len(list(backup.parent.iterdir())) == 1, 'Second installation made another backup'
        # Refuse restoration if a user replaced one of the deployed files.
        (home / '.zshrc').unlink()
        (home / '.zshrc').write_text('new user changes')
        try:
            restore(backup)
        except RuntimeError:
            pass
        else:
            raise AssertionError('Restoration overwrote later changes')
        assert (home / '.config/hypr/hyprland.lua').is_symlink(), 'Partial restoration'
        (home / '.zshrc').unlink()
        restore(backup)
        restore(backup)
    assert (home / '.zshrc').is_symlink(), 'Original broken link not restored'
    assert (home / '.config/hypr/hyprland.lua').read_text() == 'original desktop'
    assert (home / '.config/unrelated/settings').read_text() == 'keep me'
    assert not (home / '.tmux.conf').exists(), 'New link was not removed'
    assert (home / '.config/hypr/hyprland.conf').read_text() == 'legacy fallback'
print('Installer backup, dry run, idempotence, conflict handling, and rollback passed.')

with tempfile.TemporaryDirectory(prefix='dotfiles-selective-') as directory:
    home = Path(directory)
    with contextlib.redirect_stdout(io.StringIO()):
        install(home, only=['.local/bin/gitdate'])
        assert (home / '.local/bin/gitdate').is_symlink()
        assert not (home / '.zshrc').exists(), 'Selective install touched unrelated settings'
        assert not (home / '.gnupg').exists(), 'Optional GPG settings were installed by default'
        install(home, only=['.gnupg/gpg.conf'])
        assert (home / '.gnupg/gpg.conf').is_symlink()
        assert (home / '.gnupg').stat().st_mode & 0o777 == 0o700
        assert not (home / '.gnupg/gpg-agent.conf').exists()
print('Selective utility installation and opt-in GPG preferences passed.')
