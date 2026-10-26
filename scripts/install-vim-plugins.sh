#!/usr/bin/env bash
set -euo pipefail
directory="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload"
mkdir -p "$directory"
if [[ ! -f "$directory/plug.vim" ]]; then
    curl -fL --retry 2 https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim -o "$directory/plug.vim"
fi
nvim --headless '+PlugInstall --sync' '+qa'
