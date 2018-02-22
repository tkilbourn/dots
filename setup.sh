#!/bin/bash

set_git_config() {
    local gitconfig=$1
    local key=$2
    local prompt=$3

    git config -f $gitconfig --get $key >/dev/null
    if [[ $? -ne 0 ]]; then
        read -p $prompt VAL
        git config -f $gitconfig --add $key "$VAL"
    fi
}

# go home
pushd $HOME

# homedir files
home_files=(.bash_aliases .bash_exports .bash_functions .bash_profile .bashrc \
    .bash_settings .inputrc .vimrc .xmobarrc .xmobarrc-laptop .Xresources \
    .zsh_aliases .zsh_exports .zsh_functions .zsh_plugins .zshrc .zsh_settings \
    git-prompt.sh .gitconfig .ripgreprc)
for f in "${home_files[@]}"
do
    if [[ -e $f ]]; then
        diff $f dots/$f > /dev/null
        if [[ $? != 0 ]]; then
            cp $f $f.old
        fi
    fi
    ln -sf dots/$f
done

# Set up local gitconfig if it doesn't exist already
LOCAL_GITCONFIG=$HOME/.gitconfig_local
set_git_config $LOCAL_GITCONFIG user.name "Name: "
set_git_config $LOCAL_GITCONFIG user.email "Email: "

mkdir -p .zsh
ln -sf $HOME/dots/.zsh/completion .zsh/
ln -sf $HOME/dots/.zsh/functions .zsh/
ln -sf $HOME/dots/.zsh/plugins .zsh/

# xmonad files
if [[ -e .xmonad/xmonad.hs ]]; then
    diff .xmonad/xmonad.hs dots/.xmonad/xmonad.hs > /dev/null
    if [[ $? != 0 ]]; then
        cp .xmonad/xmonad.hs .xmonad/xmonad.hs.old
    fi
fi
mkdir -p .xmonad
ln -sf $HOME/dots/.xmonad/xmonad.hs .xmonad/xmonad.hs

# vim files
vim_files=(colors ftdetect ftplugin functions mappings settings syntax)
mkdir -p .vim
for f in "${vim_files[@]}"
do
    if [[ -d .vim/$f ]]; then
        mv .vim/$f .vim/$f.old
    fi
    if [[ -e .vim/$f ]]; then
        diff .vim/$f dots/.vim/$f > /dev/null
        if [[ $? != 0 ]]; then
            cp .vim/$f .vim/$f.old
        fi
    fi
    ln -sf $HOME/dots/.vim/$f .vim/$f
done
mkdir -p .vim/autoload
ln -sf $HOME/dots/vim-pathogen/autoload/pathogen.vim .vim/autoload
ln -sf $HOME/dots/.vim/bundle .vim/

popd
