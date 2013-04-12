set t_Co=256
source /home/${USER}/.vim/functions
syntax on
if exists("/usr/share/vim/google/google.vim")
  source /usr/share/vim/google/google.vim
endif

if !exists("dontcolor")
  source /home/${USER}/.vim/settings
  source /home/${USER}/.vim/colors
endif
source /home/${USER}/.vim/mappings

unlet! dontcolor
