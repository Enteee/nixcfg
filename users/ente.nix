{ pkgs, options, config, lib, ... }:

let
  myLocation = "home";
  locations = {
    home = { lat = 46.94809; long = 7.4474437; };
  };
  latlong = location: if (lib.hasAttrByPath [ location ] locations) then locations.${location} else locations.home;
  i3Modifier = "Mod4";
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

      profiles = {
        undocked = {
          fingerprint = {
            eDP-1 = "00ffffffffffff0006af362300000000001b0104a51f117802f4f5a4544d9c270f505400000001010101010101010101010101010101e65f00a0a0a040503020350035ae100000180000000f0000000000000000000000000020000000fe0041554f0a202020202020202020000000fe004231343051414e30322e33200a00b2";
          };
          config = {
            eDP-1 = {
              enable = true;
              gamma = "1.0:0.667:0.455";
              mode = "2560x1440";
              position = "0x0";
              primary = true;
              rate = "60.01";
            };
          };
        };

        vm = {
          fingerprint = {
            Virtual-1 = "--CONNECTED-BUT-EDID-UNAVAILABLE--Virtual-1";
          };
          config = {
            Virtual-1 = {
              enable = true;
              gamma = "1.0:0.625:0.357";
              mode = "1920x1080";
              position = "0x0";
              primary = true;
              rate = "60.00";
            };
          };
        };
      };
    };
  };

  xsession = {
    windowManager = {
      i3 = {
        enable = true;
        config = {
          focus.followMouse = false;
          modifier = "${i3Modifier}";
          window.titlebar = false;

          keybindings = lib.mkOptionDefault {
            # vim style navigation
            "${i3Modifier}+j" = "focus down";
            "${i3Modifier}+h" = "focus left";
            "${i3Modifier}+l" = "focus right";
            "${i3Modifier}+k" = "focus up";

            "${i3Modifier}+Shift+j" = "move down";
            "${i3Modifier}+Shift+h" = "move left";
            "${i3Modifier}+Shift+l" = "move right";
            "${i3Modifier}+Shift+k" = "move up";

            "${i3Modifier}+c" = "split h";
          };

          keycodebindings = lib.mkOptionDefault {
            # workspace 10
            "${i3Modifier}+19" = "workspace 10";
            "${i3Modifier}+Shift+19" = "move workspace 10";

            # Show the first scratchpad window
            "${i3Modifier}+20" = "scratchpad show";
            # Make the currently focused window a scratchpad
            "${i3Modifier}+Shift+20" = "move scratchpad";
          };

          modes = {
            resize = {
              Up = "resize grow up 10 px or 10 ppt";
              Down = "resize grow down 10 px or 10 ppt";
              Left = "resize grow left 10 px or 10 ppt";
              Right = "resize grow right 10 px or 10 ppt";

              "Shift+Up" = "resize shrink up 10 px or 10 ppt";
              "Shift+Down" = "resize shrink down 10 px or 10 ppt";
              "Shift+Left" = "resize shrink left 10 px or 10 ppt";
              "Shift+Right" = "resize shrink right 10 px or 10 ppt";

              k = "resize grow up 10 px or 10 ppt";
              j = "resize grow down 10 px or 10 ppt";
              h = "resize grow left 10 px or 10 ppt";
              l = "resize grow right 10 px or 10 ppt";

              "Shift+k" = "resize shrink up 10 px or 10 ppt";
              "Shift+j" = "resize shrink down 10 px or 10 ppt";
              "Shift+h" = "resize shrink left 10 px or 10 ppt";
              "Shift+l" = "resize shrink right 10 px or 10 ppt";

              Escape = "mode default";
              Return = "mode default";
            };
          };
        };
      };
    };
  };

  services = {
    redshift = {
      enable = true;
      tray = true;
      latitude = toString (latlong myLocation).lat;
      longitude = toString (latlong myLocation).long;
      temperature.night = 2500;
    };

    screen-locker = {
      enable = true;
      lockCmd = "${pkgs.i3lock}/bin/i3lock -n -c 000000";
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
