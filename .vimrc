set t_Co=256

if exists("/home/${USER}/.vim/pre-local")
  source /home/${USER}/.vim/pre-local
endif

source /home/${USER}/.vim/settings
source /home/${USER}/.vim/functions
source /home/${USER}/.vim/colors
source /home/${USER}/.vim/mappings

if exists("/home/${USER}/.vim/post-local")
  source /home/${USER}/.vim/post-local
endif
