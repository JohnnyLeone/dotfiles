#!/bin/bash
set -e

# install.sh
#	This script installs my basic setup for a fedora laptop

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
	dnf update

	# RPM Fusion Free/Nonfree
	dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

	# neovim
	dnf copr enable -y dperson/neovim

	# syncthing
	dnf copr enable -y decathorpe/syncthing
}

# install stuff for i3 window manager
install_wmapps() {
	local pkgs=( feh i3 i3lock i3status scrot lightdm neovim )

	dnf install -y "${pkgs[@]}"
}

base() {
	# base development packages
	dnf group install -y "Development Tools" "Development Libraries"

	# extra needed packages
	dnf install -y \
		asciinema \
		neovim \
		jq \
		syncthing \
		syncthing-inotify \
		powertop \
		xbacklight \
		zsh

	# install tlp with recommends
	dnf install -y tlp tlp-rdw

	dnf autoremove
	dnf clean all

	setup_sudo

	install_shell
	install_docker
	install_scripts
	install_syncthing
}

setup_sudo() {
	# add user to systemd group
	usermod -aG systemd-journal "$USERNAME"
	usermod -aG systemd-network "$USERNAME"
}

install_shell() {
	git clone git://github.com/robbyrussell/oh-my-zsh.git /home/${USERNAME}/.oh-my-zsh
	cp /home/${USERNAME}/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

	# zsh plugins
	git clone https://github.com/zsh-users/zsh-completions /home/${USERNAME}/.oh-my-zsh/custom/plugins/zsh-completions
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /home/${USERNAME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

	# set zsh as default shell
	chsh -s /bin/zsh ${USERNAME}
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

# installs docker master
# and adds necessary items to boot params
install_docker() {
	# create docker group
	sudo groupadd docker
	sudo usermod -aG docker "$USERNAME"

	dnf group install -y "Container-Management"

	systemctl daemon-reload
	systemctl enable docker
}


# install custom scripts/binaries
install_scripts() {
	# install speedtest
	curl -sSL https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest_cli.py > /usr/local/bin/speedtest
	chmod +x /usr/local/bin/speedtest

	# install icdiff
	curl -sSL https://raw.githubusercontent.com/jeffkaufman/icdiff/master/icdiff > /usr/local/bin/icdiff
	curl -sSL https://raw.githubusercontent.com/jeffkaufman/icdiff/master/git-icdiff > /usr/local/bin/git-icdiff
	chmod +x /usr/local/bin/icdiff
	chmod +x /usr/local/bin/git-icdiff

	# install lolcat
	curl -sSL https://raw.githubusercontent.com/tehmaze/lolcat/master/lolcat > /usr/local/bin/lolcat
	chmod +x /usr/local/bin/lolcat

#	local scripts=( go-md2man have light )
#
#	for script in "${scripts[@]}"; do
#		curl -sSL "https://misc.j3ss.co/binaries/$script" > "/usr/local/bin/${script}"
#		chmod +x "/usr/local/bin/${script}"
#	done
}

# install syncthing
install_syncthing() {
	systemctl daemon-reload
	systemctl enable "syncthing@${USERNAME}"
	systemctl enable "syncthing-inotify@${USERNAME}.service"
}

# install/update golang from source
install_golang() {
	export GO_VERSION=1.7.3
	export GO_SRC=/usr/local/go

	# if we are passing the version
	if [[ ! -z "$1" ]]; then
		export GO_VERSION=$1
	fi

	# purge old src
	if [[ -d "$GO_SRC" ]]; then
		sudo rm -rf "$GO_SRC"
		sudo rm -rf "$GOPATH"
	fi

	# subshell because we `cd`
	(
	curl -sSL "https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz" | sudo tar -v -C /usr/local -xz
	)

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

	aliases=( cloudflare/cfssl docker/docker letsencrypt/boulder opencontainers/runc jessfraz/binctr jessfraz/contained.af )
	for project in "${aliases[@]}"; do
		owner=$(dirname "$project")
		repo=$(basename "$project")
		if [[ -d "${HOME}/${repo}" ]]; then
			rm -rf "${HOME:?}/${repo}"
		fi

		mkdir -p "${GOPATH}/src/github.com/${owner}"

		if [[ ! -d "${GOPATH}/src/github.com/${project}" ]]; then
			(
			# clone the repo
			cd "${GOPATH}/src/github.com/${owner}"
			git clone "https://github.com/${project}.git"
			# fix the remote path, since our gitconfig will make it git@
			cd "${GOPATH}/src/github.com/${project}"
			git remote set-url origin "https://github.com/${project}.git"
			)
		else
			echo "found ${project} already in gopath"
		fi

		# make sure we create the right git remotes
		if [[ "$owner" != "jessfraz" ]]; then
			(
			cd "${GOPATH}/src/github.com/${project}"
			git remote set-url --push origin no_push
			git remote add jessfraz "https://github.com/jessfraz/${repo}.git"
			)
		fi
	done

	# do special things for k8s GOPATH
	mkdir -p "${GOPATH}/src/k8s.io"
	git clone "https://github.com/kubernetes/kubernetes.git" "${GOPATH}/src/k8s.io/kubernetes"
	)
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
	echo "  scripts                     - install scripts"
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
	elif [[ $cmd == "scripts" ]]; then
		install_scripts
	elif [[ $cmd == "syncthing" ]]; then
		install_syncthing
	else
		usage
	fi
}

main "$@"
