"""Check real interactive startup while keeping the desktop environment intact."""
import contextlib
import io
import os
import subprocess
import tempfile
from pathlib import Path
from dotfiles import install

with tempfile.TemporaryDirectory(prefix='dotfiles-shell-') as directory:
    with contextlib.redirect_stdout(io.StringIO()):
        install(Path(directory))
    env = dict(os.environ, HOME=directory, ZDOTDIR=directory,
               ZSH=str(Path.home() / '.local/share/oh-my-zsh'),
               SSH_AUTH_SOCK='/tmp/dotfiles-existing-agent',
               QT_SCALE_FACTOR='1.333333', LANG='C.UTF-8', LC_ALL='C.UTF-8')
    result = subprocess.run(['zsh', '-ic', r'''
[[ $SSH_AUTH_SOCK == /tmp/dotfiles-existing-agent ]] || exit 11
[[ $QT_SCALE_FACTOR == 1.333333 && $LC_ALL == C.UTF-8 ]] || exit 12
[[ $EDITOR == nvim && $TERMINAL == kitty ]] || exit 13
[[ $ZSH_THEME == steeef && $plugins == *vi-mode* ]] || exit 14
[[ $(urlencode 'a b&c') == 'a+b%26c' ]] || exit 15
[[ $(escape '€') == '\xE2\x82\xAC' ]] || exit 16
[[ $(codepoint '€') == U+20AC ]] || exit 17
json '{"ok":true}' >/dev/null || exit 18
gogo a-directory-that-does-not-exist >/dev/null && exit 19
[[ -x /usr/bin/git ]] || exit 20
exit 0
'''], env=env, text=True, capture_output=True)
    if result.returncode or result.stderr.strip():
        raise SystemExit(f'Zsh startup failed ({result.returncode}): {result.stdout}{result.stderr}')
print('Interactive Zsh, theme/plugins, helpers, and inherited environment passed.')
