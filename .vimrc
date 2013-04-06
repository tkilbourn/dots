set t_Co=256
source /home/tkilbourn/.vim/functions
syntax on
if exists("/usr/share/vim/google/google.vim")
  source /usr/share/vim/google/google.vim
endif

if !exists("dontcolor")
  source /home/tkilbourn/.vim/settings
  source /home/tkilbourn/.vim/colors
endif
source /home/tkilbourn/.vim/mappings

unlet! dontcolor
