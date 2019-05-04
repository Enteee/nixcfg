{ ... }:
{

  programs.vim = {
    enable = true;
    plugins = [
      "nerdtree"
      "vim-gitgutter"
      "vim-airline"
      "syntastic"
    ];
    settings = {
      number = true;
      expandtab = true;
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 4;
    };
    extraConfig = ''
      scriptencoding utf-8
      set encoding=utf-8

      set list
      set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<
      set softtabstop=2

      " Start NERDTree when vim is started with no arguments
      autocmd StdinReadPre * let s:std_in=1
      autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

      " Syntastic default configuration
      set statusline+=%#warningmsg#
      set statusline+=%{SyntasticStatuslineFlag()}
      set statusline+=%*

      let g:syntastic_always_populate_loc_list = 1
      let g:syntastic_auto_loc_list = 1
      let g:syntastic_check_on_open = 1
      let g:syntastic_check_on_wq = 0

      " Disable all autoindenting
      set nocindent
      set nosmartindent
      set noautoindent
      set indentexpr=
      filetype indent off
      filetype indent plugin off
    '';
  };

}
