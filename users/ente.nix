{ pkgs, options, config, lib, ... }:

let
  myLocation = "home";
  locations = {
    home = { lat = 46.94809; long = 7.4474437; };
  };
  latlong = location: if (lib.hasAttrByPath [ location ] locations) then locations.${location} else locations.home;
in {

  imports = [
    ../programs/git.nix
  ];

  programs = {
    home-manager.enable = true;

    bash = {
      enableAutojump = true;
    };

    firefox = {
      enable = true;
    };

    vim = {
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

    autorandr = {
      enable = true;
    };
  };

  services = {
    redshift = {
      enable = true;
      tray = true;
      latitude = toString (latlong myLocation).lat;
      longitude = toString (latlong myLocation).long;
    };
  };

}
