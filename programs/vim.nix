{ ... }:
{

  programs.vim = {
    enable = true;
    plugins = [
      "nerdtree"
    ];
    settings = {
      number = true;
      expandtab = true;
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 4;
    };
    extraConfig = ''
      set list
      set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<
      set noautoindent
      set softtabstop=2

      " Start NERDTree when vim is started with no arguments
      autocmd StdinReadPre * let s:std_in=1
      autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
    '';
  };

}
