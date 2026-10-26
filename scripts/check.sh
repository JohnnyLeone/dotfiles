#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
for config in .zshrc .aliases .functions .exports .path .dockerfunc; do
    zsh -n "$config"
done
for script in bin/*; do
    if head -n 1 "$script" | rg -q 'bash'; then bash -n "$script"; fi
done
python3 scripts/test_install.py
python3 scripts/test_shell.py
python3 scripts/test_tools.py
Hyprland --verify-config -c "$PWD/.config/hypr/hyprland.lua"
# An isolated tmux server avoids changing any existing session.
socket="dotfiles-check-$$"
trap 'tmux -L "$socket" kill-server 2>/dev/null || true' EXIT
tmux -L "$socket" -f "$PWD/.tmux.conf" new-session -d -s check 'sleep 30'
tmux -L "$socket" show-messages | if rg -i 'invalid|unknown|error'; then exit 1; else cat >/dev/null; fi
# Pencil's intentional silent! unmaps set E31 even on a successful startup.
nvim --headless -u "$PWD/.vimrc" -i NONE -c 'set filetype=markdown' \
    -c 'call assert_equal(1, &number)' -c 'call assert_equal(1, &relativenumber)' \
    -c 'if !empty(v:errors) || (!empty(v:errmsg) && v:errmsg !~# "^E31:") | cquit | endif' -c qa
printf 'Dotfiles checks passed.\n'
