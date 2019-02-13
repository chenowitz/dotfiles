#! /bin/bash
set -ex

finish() {
	 # do stuff
   # exit traps! holy shit!
	echo "finishing..."
};

trap finish EXIT INT TERM

force_ln_s() {
  # if the file doesn't exist, link it; otherwise backup the old file and link it
	if ! [ -f $2 ]; then
		ln -s $1 $2
	else
		echo "BACKUP OLD RC $1, LINKING $2"
		mv $2 $2_bkup
		ln -s $1 $2
	fi
}

install_bazel() {
	sudo mkdir -p /opt/murt
	sudo chown murt:murt /opt/murt
	git clone git@github.com:philwo/bazelisk.git /opt/murt/bazelisk
	sudo ln -s /opt/murt/bazelisk/bazelisk.py /usr/bin/bazel
}

install_docker() {
	sudo apt-get install -y \
	    apt-transport-https \
	    ca-certificates \
	    curl \
	    software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository \
	   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	   $(lsb_release -cs) \
	   stable"
	sudo apt-get update
	sudo apt-get install -y docker-ce docker-compose
	sudo usermod -aG docker $(whoami)
}

install_deps() {
	echo "Installing apt apps"
	sudo apt-get update
	sudo apt-get upgrade -y
	sudo apt-get install -y \
		git \
		tree \
		fonts-hack-ttf \
		curl \
		zsh \
		openssh-client \
		nfs-common \
		nmap \
		vim \
		clang-format \
		python \
		python3 \
		python3-pip \
		python-pip \
		rsync
# To install tilix sudo add-apt-repository ppa:webupd8team/terminix
#		tilix

	sudo chsh --shell $(which zsh) $(whoami)
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
	git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
	git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
}

symlink_dotfiles() {
	echo "this will set up dot files to their symlinks"
	#DIR=`pwd`
	DIR=$HOME/murt/dotfiles
	echo "using DIR=$DIR"

	# These are commonly installed by packages. Force the symlink by backing up existing files first if
	# the exist
	force_ln_s "$DIR/bash/bashrc" "$HOME/.bashrc"
	force_ln_s "$DIR/zsh/zshrc" "$HOME/.zshrc"
	force_ln_s "$DIR/vim/vimrc" "$HOME/.vimrc"
	force_ln_s "$DIR/git/gitconfig" "$HOME/.gitconfig"
	force_ln_s "$DIR/bash/aliases" "$HOME/.aliases"

	if ! [ -f "$HOME/.environment" ]; then ln -s $DIR/bash/environment $HOME/.environment; fi
	if ! [ -f "$HOME/.devpaths" ]; then ln -s $DIR/bash/devpaths $HOME/.devpaths; fi
	if ! [ -f "$HOME/.dockerfuncs" ]; then ln -s $DIR/docker/dockerfuncs $HOME/.dockerfuncs; fi
	if ! [ -f "$HOME/.tmux.conf" ]; then ln -s $DIR/tmux/tmux.conf $HOME/.tmux.conf; fi
	if ! [ -f "$HOME/.pythonrc" ]; then ln -s $DIR/python/pythonrc $HOME/.pythonrc; fi
}

install_snaps() {
	echo "Installing snap apps"
	sudo snap install spotify
	sudo snap install slack --classic
	sudo snap install discord
	sudo snap install atom --classic
}


## MAIN
if [ $(id -u) = 0 ]; then
   echo "Do not run this as root"
   exit 1
fi

if [ ! -f ~/.ssh/id_rsa.pub ]; then
    echo "ssh key not found!"
		echo "create an ssh key and upload it to github/lab before proceeding."
		exit 1
fi

# Only install docker and snap apps if not on crostini
if [[ $(hostname) != "penguin" ]]; then
	install_docker
	install_snaps
fi

install_deps
symlink_dotfiles
