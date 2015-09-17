#!/bin/bash

# go home
pushd $HOME

# homedir files
home_files=(.bash_aliases .bash_exports .bash_functions .bash_profile .bashrc \
    .bash_settings .inputrc .vimrc .xmobarrc .xmobarrc-laptop .Xresources \
    .zsh_aliases .zsh_exports .zsh_functions .zshrc .zsh_settings git-prompt.sh)
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
vim_files=(colors functions mappings settings)
mkdir -p .vim
for f in "${vim_files[@]}"
do
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
