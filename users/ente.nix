{ pkgs, options, config, lib, ... }:

with lib;

let
  myLocation = "home";
  locations = {
    home = { lat = 46.94809; long = 7.4474437; };
  };
  latlong = location: if (lib.hasAttrByPath [ location ] locations) then locations.${location} else locations.home;

  i3Modifier = "Mod4";

  certificatesFile = toString ../keys/public/mail.duckpond.crt;

  background = ./backgrounds/raven-background.jpg;
  background-inverted = ./backgrounds/raven-background-inverted.jpg;

  lockCmd = "${pkgs.i3lock-fancy}/bin/i3lock-fancy -p";
  lockSuspend = pkgs.writeScript "lockAndSuspend.sh"
    ''
    #!${pkgs.stdenv.shell}
    ${lockCmd} && systemctl suspend
    '';

  custom-rxvt-unicode = pkgs.rxvt-unicode.override {
    configure = { availablePlugins, ... }: {
      plugins = with availablePlugins; [
        autocomplete-all-the-things
        font-size
      ];
    };
  };

in {

  imports = [
    ../programs/git.nix
    ../programs/vim.nix
  ];

  nixpkgs.config.allowUnfree = true;

  home = {

    file.".background-image".source = background;

    packages = with pkgs; [
      manpages

      arandr

      nixpkgs-fmt

      jq

      custom-rxvt-unicode

      aspell
      aspellDicts.en
      languagetool

      thunderbird
      gnupg

      xclip
      feh
      spotify
      evince
      pwgen
      gimp
      inkscape
      unzip
      chromium
      asciinema
      wireshark
      nixops
      jre
      skypeforlinux
      hopper
      pastebinit

      virtmanager

      shellcheck

      dnsutils

      minecraft
      steam
      steam-run-native

      nixpkgs-review

      #mine.dobi
      #mine.rmapi
    ];
  };

  programs = {
    home-manager.enable = true;

    bash = {
      enable = true;
      enableAutojump = true;
      initExtra = ''
        # Hide Prompt when recording with asciinema
        if [ ! -z ''${ASCIINEMA_REC+x} ]; then
          export PS1="$ "
        fi

        # Start ipython shell with packages installed
        function ipython-nix {
          packages="pandas"
          for arg in $@; do
              packages="$packages $arg"
          done
          nix-shell -p "with python3Packages; [ ipython $packages ]" --command ipython
      }
      '';
    };

    firefox = {
      enable = true;
      enableIcedTea = true;
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
            DVI-I-1-1 = {
              enable = false;
            };
            DVI-I-2-2 = {
              enable = false;
            };
          };
        };

        docked = {
          fingerprint = {
            DVI-I-1-1 = "00ffffffffffff0004699a24cf8b01000216010380341d782a2ac5a4564f9e280f5054b7ef00714f814081809500b300d1c081c08100023a801871382d40582c450009252100001e000000ff0043314c4d54463130313332370a000000fd00324b185311000a202020202020000000fc00415355532056533234370a202001d6020322714f0102031112130414050e0f1d1e1f10230917078301000065030c0010008c0ad08a20e02d10103e9600092521000018011d007251d01e206e28550009252100001e011d00bc52d01e20b828554009252100001e8c0ad090204031200c4055000925210000180000000000000000000000000000000000000000005d";
            DVI-I-2-2 = "00ffffffffffff0004699a24dd8b01000216010380341d782a2ac5a4564f9e280f5054b7ef00714f814081809500b300d1c081c08100023a801871382d40582c450009252100001e000000ff0043314c4d54463130313334310a000000fd00324b185311000a202020202020000000fc00415355532056533234370a202001cc020322714f0102031112130414050e0f1d1e1f10230917078301000065030c0010008c0ad08a20e02d10103e9600092521000018011d007251d01e206e28550009252100001e011d00bc52d01e20b828554009252100001e8c0ad090204031200c4055000925210000180000000000000000000000000000000000000000005d";
            eDP-1 = "00ffffffffffff0006af362300000000001b0104a51f117802f4f5a4544d9c270f505400000001010101010101010101010101010101e65f00a0a0a040503020350035ae100000180000000f0000000000000000000000000020000000fe0041554f0a202020202020202020000000fe004231343051414e30322e33200a00b2";
          };
          config = {
            eDP-1 = {
              enable = false;
            };
            DVI-I-1-1 = {
              enable = true;
              gamma = "1.0:0.667:0.455";
              position = "0x0";
              mode = "1920x1080";
              primary = false;
              rate = "60.00";
            };
            DVI-I-2-2 = {
              enable = true;
              mode = "1920x1080";
              gamma = "1.0:0.667:0.455";
              position = "1920x0";
              primary = true;
              rate = "60.00";
            };
          };
        };

        vm-fullscreen = {
          fingerprint = {
            Virtual-1 = "00ffffffffffff0049143412000000002a180104a564387806ee91a3544c99260f5054210800e1c0d1c0010101010101010101010101dc960080a3a03250804c7780ef3632000018000000fd00327d1ea078010a202020202020000000fc0051454d55204d6f6e69746f720a000000f7000a004aa2242920000000000000018b02030a00457d6560591f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2";
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

        vm-fullscreen-docked = {
          fingerprint = {
            Virtual-1 = "00ffffffffffff0049143412000000002a180104a54b2a7806ee91a3544c99260f5054210800e1c0d1c0010101010101010101010101d25480a072382540e0395540f3a921000018000000fd00327d1ea078010a202020202020000000fc0051454d55204d6f6e69746f720a000000f7000a004aa224292000000000000001c302030a00457d6560591f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2";
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

#       vm-window = {
#         fingerprint = {
#           Virtual-1 = "00ffffffffffff0049143412000000002a180104a564377806ee91a3544c99260f5054210800e1c0d1c0010101010101010101010101d592fa7d937d31507e4c7780ed2932000018000000fd00327d1ea078010a202020202020000000fc0051454d55204d6f6e69746f720a000000f7000a004aa224292000000000000001e502030a00457d6560591f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2";
#         };
#         config = {
#           Virtual-1 = {
#             enable = true;
#             gamma = "1.0:0.625:0.357";
#             mode = "1920x1080";
#             position = "0x0";
#             primary = true;
#             rate = "60.00";
#           };
#         };
#       };

#       vm-window-docked = {
#         fingerprint = {
#           Virtual-1 = "00ffffffffffff0049143412000000002a180104a54b297806ee91a3544c99260f5054210800e1c0d1c0010101010101010101010101cd517a9d72152440de395540f19b21000018000000fd00327d1ea078010a202020202020000000fc0051454d55204d6f6e69746f720a000000f7000a004aa2242920000000000000010b02030a00457d6560591f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2";
#         };
#         config = {
#           Virtual-1 = {
#             enable = true;
#             gamma = "1.0:0.625:0.357";
#             mode = "1920x1080";
#             position = "0x0";
#             primary = true;
#             rate = "60.00";
#           };
#         };
#       };
      };
    };
  };

  xsession = {
    windowManager = {
      i3 = {
        enable = true;
        config = {
          modifier = i3Modifier;

          focus.followMouse = false;

          window.titlebar = false;

          window.commands = [
            # qemu always fulscreen
            {
              command = "move down; resize set 1920 1080";
              criteria = { class = "qemu-system-x86_64"; };
            }
          ];

          keybindings = mkOptionDefault {
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
            "${i3Modifier}+a" = "focus parent";

            # Arrow keys move workspaces
            "${i3Modifier}+Down" = "move workspace to output down";
            "${i3Modifier}+Left" = "move workspace to output left";
            "${i3Modifier}+Right" = "move workspace to output right";
            "${i3Modifier}+Up" = "move workspace to output up";

            "${i3Modifier}+Shift+Down" = "move container to output down";
            "${i3Modifier}+Shift+Left" = "move container to output left";
            "${i3Modifier}+Shift+Right" = "move container to output right";
            "${i3Modifier}+Shift+Up" = "move container to output up";

            # locking and suspending
            "${i3Modifier}+o" = "exec --no-startup-id ${lockCmd}";
            "${i3Modifier}+p" = "exec --no-startup-id ${lockSuspend}";
          };

          keycodebindings = mkOptionDefault {
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
      lockCmd = "${lockCmd}";
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
    "URxvt.url-launcher" = "${pkgs.firefox}/bin/firefox";
    "URxvt.matcher.button" = 2;

    "URxvt.perl-ext-common" = "autocomplete-ALL-the-things,font-size";

    # Autocomplete all the things
    "URxvt.keysym.M-C-slash" = "perl:aAtt:word-complete";
    "URxvt.keysym.M-question" = "perl:aAtt:fuzzy-complete";
    "URxvt.keysym.M-quotedbl" = "perl:aAtt:undo";

    # font size
    "URxvt.keysym.C-Up" = "font-size:increase";
    "URxvt.keysym.C-Down" = "font-size:decrease";
    "URxvt.keysym.C-S-Up" = "font-size:incglobal";
    "URxvt.keysym.C-S-Down" = "font-size:decglobal";
    "URxvt.keysym.C-equal" = "font-size:reset";
    "URxvt.keysym.C-slash" = "font-size:show";

    # HIDPI
    "Xft.dpi" = 144;
    "Xft.autohint" = 0;
    "Xft.lcdfilter" = "lcddefault";
    "Xft.hintstyle" = "hintfull";
    "Xft.hinting" = 1;
    "Xft.antialias" = 1;
    "Xft.rgba" = "rgb";
  };

}
