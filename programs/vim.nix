{ pkgs , ...  }:

with pkgs;

let
  default_ycm_extra_conf = builtins.fetchurl {
    name = "ycm_extra_conf.py";
    url = "https://raw.githubusercontent.com/ycm-core/ycmd/a24204e8382d0660a519f88b59c67026f453c085/.ycm_extra_conf.py";
    sha256 = "1p0z9rvmvr53lwl8xrby6fmf1lcfl3rzz2k6sph1j1v1cxvj9nyy";
  };

  make_ycm_extra_conf = writeShellScriptBin "make_ycm_extra_conf" ''
    dst="''${1:-"."}/.ycm_extra_conf.py"

    echo "Writing: ''${dst}"
    install "${default_ycm_extra_conf}" "''${dst}"
    '';

in {

  home.packages = [
    make_ycm_extra_conf
  ];

  programs.vim = {
    enable = true;

    plugins = with vimPlugins; [
      nerdtree
      vim-gitgutter
      vim-airline
      syntastic
      YouCompleteMe

      # Languages
      rust-vim
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
      set softtabstop=2

      " Define leader
      let mapleader = " "

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

      " Syntax highlighting for .ejs files
      " https://stackoverflow.com/questions/4597721/syntax-highlight-for-ejs-files-in-vim
      au BufNewFile,BufRead *.ejs set filetype=html

      " Display max line lenght indicator
      set colorcolumn=80

      " Disable all autoindenting
      set nocindent
      set nosmartindent
      set noautoindent
      set indentexpr=
      filetype indent off
      filetype indent plugin off

      " Insert Tab with shift+tab
      inoremap <S-Tab> <C-V><Tab>

      " YouCompleteMe default configuration
      nmap <leader>D <plug>(YCMHover)
    '';
  };

}
