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

  xresources.properties = {
    "URxvt.saveLines" = 1000;

    "URxvt.scrollBar" = "off";
    "URxvt.secondaryScroll" = "off";

    "URxvt.foreground" = "white";
    "URxvt.background" = "black";
    "URxvt.shading" = 20;

    # Theme: Twenty-Five
    "*color0" = "rgb:00/00/00";
    "*color1" = "rgb:d0/00/00";
    "*color2" = "rgb:00/80/00";
    "*color3" = "rgb:d0/d0/90";
    "*color4" = "rgb:00/00/80";
    "*color5" = "rgb:80/00/80";
    "*color6" = "rgb:a6/ca/f0";
    "*color7" = "rgb:d0/d0/d0";
    "*color8" = "rgb:b0/b0/b0";
    "*color9" = "rgb:f0/80/60";
    "*color10" = "rgb:60/f0/80";
    "*color11" = "rgb:e0/c0/60";
    "*color12" = "rgb:80/c0/e0";
    "*color13" = "rgb:f0/c0/f0";
    "*color14" = "rgb:c0/d8/f8";
    "*color15" = "rgb:e0/e0/e0";

    # Scroll options
    "URxvt.scrollTtyOutput" = false;
    "URxvt.scrollWithBuffer" = true;
    "URxvt.scrollTtyKeypress" = true;

    # Fonts
    "!URxvt.font" = "xft:Inconsolata:pixelsize=15:antialias=true";
    "*.font" = "xft:Inconsolata:pixelsize=22:antialias=true";

    # urls clicky clicky
    "URxvt.perl-ext" = "default,matcher";
    "URxvt.url-launcher" = "firefox";
    "URxvt.matcher.button" = 1;

    # font size
    "URxvt.perl-ext-common" = "font-size";
    "URxvt.keysym.C-Up" = "font-size:increase";
    "URxvt.keysym.C-Down" = "font-size:decrease";
    "URxvt.keysym.C-S-Up" = "font-size:incglobal";
    "URxvt.keysym.C-S-Down" = "font-size:decglobal";
    "URxvt.keysym.C-equal" = "font-size:reset";
    "URxvt.keysym.C-slash" = "font-size:show";

    # HIDPI
    "Xft.dpi" = 150;
    "Xft.autohint" = 0;
    "Xft.lcdfilter" = "lcddefault";
    "Xft.hintstyle" = "hintfull";
    "Xft.hinting" = 1;
    "Xft.antialias" = 1;
    "Xft.rgba" = "rgb";
  };

}
