#!/bin/bash

# go home
pushd $HOME

# homedir files
home_files=(.bash_aliases .bash_exports .bash_functions .bash_profile .bashrc \
    .bash_settings .inputrc .vimrc .xmobarrc .xmobarrc-laptop .Xresources \
    .zsh_aliases .zsh_exports .zsh_functions .zshrc .zsh_settings)
for f in "${home_files[@]}"
do
    if [ -e $f ]
    then
        cp $f $f.old
    fi
    ln -sf dots/$f
done

mkdir -p .zsh
ln -sf $HOME/dots/.zsh/functions .zsh/functions

# xmonad files
if [ -e .xmonad/xmonad.hs ]
then
    cp .xmonad/xmonad.hs .xmonad/xmonad.hs.old
fi
mkdir -p .xmonad
ln -sf $HOME/dots/.xmonad/xmonad.hs .xmonad/xmonad.hs

# vim files
vim_files=(colors functions mappings settings)
mkdir -p .vim
for f in "${vim_files[@]}"
do
    if [ -e .vim/$f ]
    then
        cp .vim/$f .vim/$f.old
    fi
    ln -sf $HOME/dots/.vim/$f .vim/$f
done
mkdir -p .vim/autoload
ln -sf $HOME/dots/vim-pathogen/autoload/pathogen.vim .vim/autoload
ln -sf $HOME/dots/.vim/bundle .vim/bundle

popd
