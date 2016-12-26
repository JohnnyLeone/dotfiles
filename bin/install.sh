#!/bin/bash
set -e

# install.sh
#	This script installs my basic setup for a arch laptop

USERNAME=ahirschauer

check_is_sudo() {
	if [ "$EUID" -ne 0 ]; then
		echo "Please run as root."
		exit
	fi
}

# sets up apt sources
# assumes you are going to use debian stretch
setup_sources() {
	pacman -Syu
}

# install stuff for i3 window manager
install_wmapps() {
	local pkgs=( feh i3 i3lock i3status scrot neovim )

	pacman -S --needed --noconfirm "${pkgs[@]}"
}

base() {
	# base development packages
	pacman -S --needed --noconfirm base-devel

	# extra needed packages
	pacman -S --needed --noconfirm \
		arc-gtk-theme \
		arc-icon-theme \
		asciinema \
		jq \
		lolcat \
		neovim \
		ranger \
		syncthing \
		syncthing-inotify \
		powertop \
		xorg-xbacklight \
		zsh

	# install powertop and tlp with recommends
	pacman -S --needed --noconfirm powertop tlp tlp-rdw

	pacman -Sc

	setup_sudo

	install_shell
	install_docker
	install_syncthing
}

setup_sudo() {
	# add user to systemd group
	usermod -aG systemd-journal "$USERNAME"
	usermod -aG systemd-network "$USERNAME"

	# add go path to secure path
	{ \
		echo -e 'Defaults	secure_path="/usr/local/go/bin:/home/ahirschauer/.go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"'; \
		echo -e 'Defaults	env_keep += "ftp_proxy http_proxy https_proxy no_proxy GOPATH EDITOR"'; \
		echo -e "${USERNAME} ALL=(ALL) NOPASSWD:ALL"; \
		echo -e "${USERNAME} ALL=NOPASSWD: /sbin/ifconfig, /sbin/ifup, /sbin/ifdown, /sbin/ifquery"; \
	} >> /etc/sudoers

	# setup downloads folder as tmpfs
	# that way things are removed on reboot
	# i like things clean but you may not want this
	mkdir -p "/home/$USERNAME/Downloads"
	echo -e "\n# tmpfs for downloads\ntmpfs\t/home/${USERNAME}/Downloads\ttmpfs\tnodev,nosuid,size=2G\t0\t0" >> /etc/fstab
}

install_shell() {
	git clone git://github.com/robbyrussell/oh-my-zsh.git /home/${USERNAME}/.oh-my-zsh
	cp /home/${USERNAME}/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

	# zsh plugins
	git clone https://github.com/zsh-users/zsh-completions /home/${USERNAME}/.oh-my-zsh/custom/plugins/zsh-completions
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /home/${USERNAME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

	# set zsh as default shell
	chsh -s /bin/zsh ${USERNAME}

	# install gdb-peda
	git clone https://github.com/longld/peda.git /home/${USERNAME}/peda
	echo "source /home/${USERNAME}/peda/peda.py" >> /home/${USERNAME}/.gdbinit
}

get_dotfiles() {
	# create subshell
	(
	cd "$HOME"

	# install dotfiles from repo
	git clone --recursive git@github.com:johnnyleone/dotfiles.git "${HOME}/dotfiles"
	cd "${HOME}/dotfiles"

	# installs all the things
	make

	# install powerline fonts
	cd fonts
	./install.sh

	cd "$HOME"
	mkdir -p ~/Pictures
	)
}

install_vim() {
	curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

# installs docker
install_docker() {
	pacman -S docker

	usermod -aG docker "$USERNAME"

	systemctl daemon-reload
	systemctl enable docker
}

# install syncthing
install_syncthing() {
	systemctl daemon-reload
	systemctl enable "syncthing@${USERNAME}"
	systemctl enable "syncthing-inotify@${USERNAME}.service"
}

# install/update golang from source
install_golang() {
	sudo pacman -S go

	# get commandline tools
	(
	set -x
	set +e
	go get github.com/golang/lint/golint
	go get golang.org/x/tools/cmd/cover
	go get golang.org/x/review/git-codereview
	go get golang.org/x/tools/cmd/goimports
	go get golang.org/x/tools/cmd/gorename
	go get golang.org/x/tools/cmd/guru

	go get github.com/jessfraz/apk-file
	go get github.com/jessfraz/audit
	go get github.com/jessfraz/bane
	go get github.com/jessfraz/battery
	go get github.com/jessfraz/cliaoke
	go get github.com/jessfraz/ghb0t
	go get github.com/jessfraz/magneto
	go get github.com/jessfraz/netns
	go get github.com/jessfraz/netscan
	go get github.com/jessfraz/onion
	go get github.com/jessfraz/pastebinit
	go get github.com/jessfraz/pony
	go get github.com/jessfraz/reg
	go get github.com/jessfraz/riddler
	go get github.com/jessfraz/udict
	go get github.com/jessfraz/weather

	go get github.com/axw/gocov/gocov
	go get github.com/brianredbeard/gpget
	go get github.com/cloudflare/cfssl/cmd/cfssl
	go get github.com/cloudflare/cfssl/cmd/cfssljson
	go get github.com/crosbymichael/gistit
	go get github.com/crosbymichael/ip-addr
	go get github.com/cbednarski/hostess/cmd/hostess
	go get github.com/davecheney/httpstat
	go get github.com/FiloSottile/gvt
	go get github.com/FiloSottile/vendorcheck
	go get github.com/nsf/gocode
	go get github.com/rogpeppe/godef
	go get github.com/shurcooL/git-branches
	go get github.com/shurcooL/gostatus
	go get github.com/shurcooL/markdownfmt
	go get github.com/Soulou/curl-unix-socket
}

install_kvm() {
	pacman -S --needed --noconfirm qemu virt-manager virt-viewer dnsmasq iptables ebtables vde2 bridge-utils openbsd-netcat

	usermod -aG kvm "$USERNAME"

	systemctl daemon-reload
	systemctl enable libvirtd
}

usage() {
	echo -e "install.sh\n\tThis script installs my basic setup for a debian laptop\n"
	echo "Usage:"
	echo "  sources                     - setup sources & install base pkgs"
	echo "  wm                          - install window manager/desktop pkgs"
	echo "  shell                       - install oh-my-zsh and plugins"
	echo "  dotfiles                    - get dotfiles"
	echo "  vim                         - install vim specific dotfiles"
	echo "  golang                      - install golang and packages"
	echo "  kvm                         - install kvm
	echo "  syncthing                   - install syncthing"
}

main() {
	local cmd=$1

	if [[ -z "$cmd" ]]; then
		usage
		exit 1
	fi

	if [[ $cmd == "sources" ]]; then
		check_is_sudo

		setup_sources

		base
	elif [[ $cmd == "wm" ]]; then
		check_is_sudo

		install_wmapps
	elif [[ $cmd == "shell" ]]; then
		install_shell
	elif [[ $cmd == "dotfiles" ]]; then
		get_dotfiles
	elif [[ $cmd == "vim" ]]; then
		install_vim
	elif [[ $cmd == "golang" ]]; then
		install_golang "$2"
    elif [[ $cmd == "kvm" ]]; then
		check_is_sudo

		install_kvm
	elif [[ $cmd == "syncthing" ]]; then
		install_syncthing
	else
		usage
	fi
}

main "$@"
