.PHONY: all dotfiles install dry-run check test vim-plugins

all: dotfiles

dotfiles install:
	python3 scripts/dotfiles.py install

dry-run:
	python3 scripts/dotfiles.py install --dry-run

check test:
	bash scripts/check.sh

vim-plugins:
	bash scripts/install-vim-plugins.sh

