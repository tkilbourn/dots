set t_Co=256

if filereadable($HOME . "/.vim/pre-local")
  source $HOME/.vim/pre-local
endif

execute pathogen#infect()

source $HOME/.vim/settings
source $HOME/.vim/functions
source $HOME/.vim/colors
source $HOME/.vim/mappings

if filereadable($HOME . "/.vim/post-local")
  source $HOME/.vim/post-local
endif
