#!/bin/bash

VAGRANT="2.1.5"
VAGRANT_BOXES="bento/centos-7 bento/centos-6 bento/debian-8 bento/debian-9 bento/ubuntu-16.04 bento/ubuntu-18.04 jacqinthebox/windows10LTSB"

PWD=$(pwd)

cd
stat setup &>/dev/null || mkdir setup; cd setup

# Puppet 5
sudo rpm --import https://yum.puppet.com/RPM-GPG-KEY-puppet
sudo rpm -aq |grep puppet5-release 1>/dev/null || sudo yum install -y http://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm
sudo rpm -q puppet-agent &>/dev/null || sudo yum install -y puppet-agent
sudo rpm -q puppet-bolt &>/dev/null || sudo yum install -y puppet-bolt

sudo cp /opt/puppetlabs/puppet/share/vim/puppet-vimfiles/indent/puppet.vim /usr/share/vim/vimfiles/indent/ 1>/dev/null
sudo cp /opt/puppetlabs/puppet/share/vim/puppet-vimfiles/ftplugin/puppet.vim /usr/share/vim/vimfiles/ftplugin/ 1>/dev/null
sudo cp /opt/puppetlabs/puppet/share/vim/puppet-vimfiles/ftdetect/puppet.vim /usr/share/vim/vimfiles/ftdetect/ 1>/dev/null

grep ^PATH= ~/.bashrc 1>/dev/null || cat << EOF >> ~/.bashrc

PATH=\$PATH:\$HOME/bin
export PATH
EOF

grep ^PATH=.*:/opt/puppetlabs/bolt/bin ~/.bashrc 1>/dev/null || sed -i 's|^PATH=\(.*\)$|PATH=\1:/opt/puppetlabs/bolt/bin|g' ~/.bashrc

# Git
sudo rpm -q git &>/dev/null || sudo yum install -y git

cat << EOF > git.sh
function is_on_git() {
  git rev-parse 2> /dev/null
}

function parse_git_dirty() {
  REGEX="working (tree|directory) clean"
  [[ \$(git status 2> /dev/null | tail -n1) =~ \$REGEX ]] || echo "±"
}

function parse_git_branch() {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1\$(parse_git_dirty)/"
}

export DEFAULT="\033[1;39m"
export BLACK="\033[1;30m"
export RED="\033[1;31m"
export GREEN="\033[1;32m"
export YELLOW="\033[1;33m"
export BLUE="\033[1;34m"
export MAGENTA="\033[1;35m"
export CYAN="\033[1;36m"
export GRAY="\033[1;90m"
export WHITE="\033[1;97m"
export BOLD=""
export RESET="\033[m"

export PS1="\[\${GRAY}\]\u@\[\${GRAY}\]\h \[\${BLUE}\]\w\\\$(is_on_git && [[ -n \\\$(git branch 2> /dev/null) ]] && echo \":\")\[\${RED}\]\\\$(parse_git_branch)\[\${RESET}\]$ "
EOF

sudo mv git.sh /etc/profile.d/

cat << EOF > ~/.gitconfig
# This is Git's per-user configuration file.
[user]
# Please adapt and uncomment the following lines:
	name = Trainings Member
	email = training@localhost
EOF


# Vagrant
stat "vagrant_${VAGRANT}_x86_64.rpm" &>/dev/null || wget "https://releases.hashicorp.com/vagrant/${VAGRANT}/vagrant_${VAGRANT}_x86_64.rpm"
sudo rpm -q vagrant &>/dev/null || sudo yum localinstall -y "vagrant_${VAGRANT}_x86_64.rpm"

for box in $VAGRANT_BOXES; do
  vagrant box list |grep $box &>/dev/null || vagrant box add $box --provider virtualbox
done

cd $PWD
