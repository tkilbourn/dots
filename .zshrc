typeset -U path

case $- in
    *i*) ;;
    *) return;;
esac

if [ -r ~/.zsh_aliases ]; then
    . ~/.zsh_aliases
fi

if [ -r ~/.zsh_exports ]; then
    . ~/.zsh_exports
fi

if [ -r ~/.zsh_settings ]; then
    . ~/.zsh_settings
fi

if [ -r ~/.zsh_functions ]; then
    . ~/.zsh_functions
fi

if [ -r ~/.zsh_plugins ]; then
    . ~/.zsh_plugins
fi

if [ -r ~/.zsh_local ]; then
    . ~/.zsh_local
fi
