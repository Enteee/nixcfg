{ pkgs, options, config, lib, ... }:

with lib;
let
  autorandr = "${pkgs.autorandr}/bin/autorandr";
  xrdb = "${pkgs.xorg.xrdb}/bin/xrdb";
  cat = "${pkgs.coreutils}/bin/cat";
  i3-msg = "${pkgs.i3}/bin/i3-msg";
  feh-cmd = "${pkgs.feh}/bin/feh";

  myLocation = "home";
  locations = {
    home = { lat = 46.94809; long = 7.4474437; };
  };
  latlong = location: if (lib.hasAttrByPath [ location ] locations) then locations.${location} else locations.home;

  i3Modifier = "Mod4";

  background = ./backgrounds/raven-background.jpg;
  background-inverted = ./backgrounds/raven-background-inverted.jpg;

  lockCmd = "${pkgs.i3lock}/bin/i3lock --color 000000";
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

  i3StatusConfig = pkgs.writeText "i3StatusRust.conf" ''
    # i3status configuration file.
    # see "man i3status" for documentation.

    # It is important that this file is edited as UTF-8.
    # The following line should contain a sharp s: ß
    # If the above line is not correctly displayed, fix your editor first!

    general {
      colors = true
      interval = 5
    }

    order += "ipv6"
    order += "wireless _first_"
    order += "wireless wwp0s20f0u6"
    order += "ethernet _first_"
    order += "battery all"
    order += "disk /"
    order += "load"
    order += "memory"
    order += "tztime local"

    wireless _first_ {
            format_up = "W: (%quality at %essid) %ip"
            format_down = "W: down"
    }

    wireless wwp0s20f0u6 {
            format_up = "W: %ip"
            format_down = "W: down"
    }

    ethernet _first_ {
            format_up = "E: %ip (%speed)"
            format_down = "E: down"
    }

    battery all {
            format = "%status %percentage %remaining"
    }

    disk "/" {
            format = "%avail"
    }

    load {
            format = "%1min"
    }

    memory {
            format = "%used | %available"
            threshold_degraded = "1G"
            format_degraded = "MEMORY < %available"
    }

    tztime local {
            format = "%Y-%m-%d %H:%M:%S"
    }
  '';

  loadBackground = pkgs.writeScript "load-background.sh"
    ''
    #!${pkgs.stdenv.shell}
    if [ -e $HOME/.background-image ]; then
      ${feh-cmd} --bg-scale $HOME/.background-image
    fi
    '';

in {

  imports = [
    ../overlays

    ../envs

    ../programs/git.nix
    ../programs/vim.nix
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "p7zip-16.02"
  ];

  fonts.fontconfig.enable = true;

  # enable support for custom environments
  envs.enable = true;

  home = {

    file.".background-image".source = background;

    # Disable Vertical Synchronization: DisplayLink sems to have
    # problems when vsync is enabled.
    # https://github.com/DisplayLink/evdi/issues/186
    # https://wiki.archlinux.org/index.php/Intel_graphics#Disable_Vertical_Synchronization_.28VSYNC.29
    file.".drirc".text = ''
      <device screen="0" driver="dri2">
        <application name="Default">
          <option name="vblank_mode" value="0"/>
        </application>
      </device>
      '';

    packages = with pkgs; [
      manpages

      arandr

      nix-review
      nixpkgs-fmt
      #nixops

      bc

      jq

      gnome3.defaultIconTheme

      aspell
      aspellDicts.en
      aspellDicts.de
      languagetool

      thunderbird
      pinentry-qt

      spotify

      pavucontrol
      pulseeffects

      gimp
      inkscape

      xclip
      feh
      evince
      pwgen
      unzip
      meld

      chromium
      asciinema

      wireshark

      #skypeforlinux

      hopper
      hexedit

      pastebinit

      virtmanager
      virt-viewer

      shellcheck

      binutils
      dnsutils

      minecraft
      lutris
      steam

      torbrowser
      discord

      rmapi

      #mine.dobi
      mine.i3-get-window-criteria
    ];
  };


  programs = {
    home-manager.enable = true;

    bash = {
      enable = true;
      initExtra = ''
        # shell name indicator
        if [ ! -z "''${SHELL_NAME}" ]; then
          export PS1="\e[0;31m(''${SHELL_NAME})\e[m ''${PS1}"
        fi

        # Hide Prompt when recording with asciinema
        if [ ! -z ''${ASCIINEMA_REC+x} ]; then
          export PS1="$ "
        fi

        # Start ipython shell with packages installed
        function ipython-nix {
          packages=""
          for arg in $@; do
              packages="$packages $arg"
          done
          nix-shell -p "with python3Packages; [ ipython $packages ]" --command ipython
        }
      '';
    };

    urxvt = {
      enable = true;
      package = custom-rxvt-unicode;
      fonts = [
        # Does not work:
        # https://github.com/googlefonts/Inconsolata/issues/42
        #"xft:Inconsolata:pixelsize=15:antialias=true"

        # Set system wide in xresource:
        #"xft:Inconsolata Regular:family=mono:pixelsize=22:antialias=true"
      ];
      scroll.bar.enable = false;
      extraConfig = {
        "saveLines" = 1000;

        "secondaryScroll" = "off";

        "shading" = 20;

        # Scroll options
        "scrollTtyOutput" = false;
        "scrollWithBuffer" = true;
        "scrollTtyKeypress" = true;

        # urls clicky clicky
        "perl-ext" = "default,matcher";
        "url-launcher" = "${pkgs.firefox}/bin/firefox";
        "matcher.button" = 2;

        "perl-ext-common" = "autocomplete-ALL-the-things,font-size";

        # Autocomplete all the things
        "keysym.M-C-slash" = "perl:aAtt:word-complete";
        "keysym.M-question" = "perl:aAtt:fuzzy-complete";
        "keysym.M-quotedbl" = "perl:aAtt:undo";

        # font size
        "keysym.C-Up" = "font-size:increase";
        "keysym.C-Down" = "font-size:decrease";
        "keysym.C-S-Up" = "font-size:incglobal";
        "keysym.C-S-Down" = "font-size:decglobal";
        "keysym.C-equal" = "font-size:reset";
        "keysym.C-slash" = "font-size:show";

      };
    };

    # jump to previously used folders using 'j'
    autojump.enable = true;

    firefox = {
      enable = true;
      profiles.default.userChrome = ''
        /* Hide tab bar in FF Quantum */
        #TabsToolbar {
          visibility: collapse !important;
          margin-bottom: 21px !important;
        }

        #sidebar-box[sidebarcommand="treestyletab_piro_sakura_ne_jp-sidebar-action"] #sidebar-header {
          visibility: collapse !important;
        }
        '';
    };

    autorandr = {
      enable = true;

      hooks.postswitch = {
        "notify-i3" = "${i3-msg} restart";
        "load-background" = "${loadBackground}";
      };

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
          hooks.postswitch = ''
            ${cat} <<EOF | ${xrdb} -merge -
              Xft.dpi:  144
              *.font:   xft:Inconsolata Regular:family=mono:pixelsize=22:antialias=true
            EOF
          '';
        };

        docked = {
          fingerprint = {
            DVI-I-1-1 = "00ffffffffffff004c2d670b3336333006190103803c22782a9791a556549d250e5054bfef80714f81c0810081809500a9c0b3000101023a801871382d40582c450056502100001e011d007251d01e206e28550056502100001e000000fd00324b1e5111000a202020202020000000fc00533237443339300a202020202001ff02031af14690041f130312230907078301000066030c00100080011d00bc52d01e20b828554056502100001e8c0ad090204031200c4055005650210000188c0ad08a20e02d10103e9600565021000018000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000061";
            DVI-I-2-2 = "00ffffffffffff004c2d670b3336333032180103803c22782a9791a556549d250e5054bfef80714f81c0810081809500a9c0b3000101023a801871382d40582c450056502100001e011d007251d01e206e28550056502100001e000000fd00324b1e5111000a202020202020000000fc00533237443339300a202020202001d402031af14690041f130312230907078301000066030c00100080011d00bc52d01e20b828554056502100001e8c0ad090204031200c4055005650210000188c0ad08a20e02d10103e9600565021000018000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000061";
            eDP-1 = "00ffffffffffff0006af362300000000001b0104a51f117802f4f5a4544d9c270f505400000001010101010101010101010101010101e65f00a0a0a040503020350035ae100000180000000f0000000000000000000000000020000000fe0041554f0a202020202020202020000000fe004231343051414e30322e33200a00b2";
          };
          config = {
            eDP-1 = {
              enable = false;
            };
            DVI-I-1-1 = {
              enable = true;
              gamma = "1.0:0.667:0.455";
              position = "1920x0";
              mode = "1920x1080";
              primary = true;
              rate = "60.00";
            };
            DVI-I-2-2 = {
              enable = true;
              mode = "1920x1080";
              gamma = "1.0:0.667:0.455";
              position = "0x0";
              primary = true;
              rate = "60.00";
            };
          };
          hooks.postswitch = ''
              ${cat} <<EOF | ${xrdb} -merge -
                Xft.dpi:  120
                *.font:   xft:Inconsolata Regular:family=mono:pixelsize=17:antialias=true
              EOF
            '';
        };

        docked-other = {
          fingerprint = {
            DP2-3 = "00ffffffffffff00410c2b09d60a00000c1d0104b54627783a6871a6564fa2260e5054bfef00d1c0b30095008180814081c001010101e2ca0038f0703e8018103500b9882100001aa36600a0f0701f8030203500b9882100001a000000fc0050484c2033323950390a202020000000fd0017501ea03c010a2020202020200138020320f14b0103051404131f12021190230907078301000067030c0010001878565e00a0a0a0295030203500b9882100001e023a801871382d40582c4500b9882100001e011d007251d01e206e285500b9882100001e8c0ad08a20e02d10103e9600b988210000184d6c80a070703e8030203a00b9882100001a00000000001c";
            eDP-1 = "00ffffffffffff0006af362300000000001b0104a51f117802f4f5a4544d9c270f505400000001010101010101010101010101010101e65f00a0a0a040503020350035ae100000180000000f0000000000000000000000000020000000fe0041554f0a202020202020202020000000fe004231343051414e30322e33200a00b2";
          };
          config = {
            DP2-3 = {
              enable = true;
              gamma = "1.0:0.667:0.455";
              position = "0x0";
              mode = "3840x2160";
              primary = true;
              rate = "30.00";
            };
            eDP-1 = {
              enable = false;
              mode = "2560x1440";
              gamma = "1.0:0.667:0.455";
              position = "3840x0";
              primary = false;
              rate = "60.00";
            };
          };
          hooks.postswitch = ''
              ${cat} <<EOF | ${xrdb} -merge -
                Xft.dpi:  144
                *.font:   xft:Inconsolata Regular:family=mono:pixelsize=22:antialias=true
              EOF
            '';
        };

        fixed = {
          fingerprint = {
            DVI-D-0 = "00ffffffffffff0004699a24cf8b01000216010380341d782a2ac5a4564f9e280f5054b7ef00714f814081809500b300d1c081c08100023a801871382d40582c450009252100001e000000ff0043314c4d54463130313332370a000000fd00324b185311000a202020202020000000fc00415355532056533234370a202000d7";
            DVI-I-1 = "00ffffffffffff0004699a24dd8b01000216010380341d782a2ac5a4564f9e280f5054b7ef00714f814081809500b300d1c081c08100023a801871382d40582c450009252100001e000000ff0043314c4d54463130313334310a000000fd00324b185311000a202020202020000000fc00415355532056533234370a202000cd";
          };
          config = {
            eDP-1 = {
              enable = false;
            };
            DVI-D-0 = {
              enable = true;
              gamma = "1.0:0.667:0.455";
              position = "0x0";
              mode = "1920x1080";
              primary = false;
              rate = "60.00";
            };
            DVI-I-1 = {
              enable = true;
              mode = "1920x1080";
              gamma = "1.0:0.667:0.455";
              position = "1920x0";
              primary = true;
              rate = "60.00";
            };
          };
        };

      };
    };

    vscode = {
      enable = true;
      userSettings = {
        telemetry.enableTelemetry = false;
        java.home = "${pkgs.jdk}/lib/openjdk";
        python.pythonPath = pkgs.python3.withPackages(ps: with ps; [
          pylint
          autopep8
        ]);
        files.exclude = {
          # Java excludes
          "**/.classpath" = true;
          "**/.project" = true;
          "**/.settings" = true;
          "**/.factorypath" = true;
        };
        cmake.configureOnOpen = true;
      };
      extensions = (with pkgs.vscode-extensions; [
        vscodevim.vim

        # Language specific
        ms-vscode.cpptools
        xaver.clang-format

        ms-python.python

        golang.Go

        bbenoist.Nix
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "vscode-java-pack";
          publisher = "vscjava";
          version = "0.12.0";
          sha256 = "1w0w6gdc0ppqfdhji132iwqn0cz09vsng6fps96031vdpzgqdd0x";
        }
        {
          name = "java";
          publisher = "redhat";
          version = "0.73.0";
          sha256 = "0hs45133kwpq8c2bp1gwpggf2xnbnkxrmswbivpk4x9fml8yw9rg";
        }
        {
          name = "cmake-tools";
          publisher = "ms-vscode";
          version = "1.5.3";
          sha256 = "sha256-DfVaWe1P902XGWayLfaiooHbIviQpj5EXtyTxHRGWvg=";
        }
        {
          name = "nix-env-selector";
          publisher = "arrterian";
          version = "0.1.2";
          sha256 = "sha256-aTNxr1saUaN9I82UYCDsQvH9UBWjue/BSnUmMQOnsdg=";
        }
      ]);
    };

  };

  xsession = {

    enable = true;

    numlock.enable = true;

    initExtra = ''
        # Copy PRIMARY to CLIPBOARD
        # -> Make highlighted text pastable with CTRL+V
        ${pkgs.autocutsel}/bin/autocutsel -fork

        # Copy CLIPBOARD to PRIMARY
        # -> Make CTR+C pastable with SHIFT+INSERT or by clicking the middle mouse button
        ${pkgs.autocutsel}/bin/autocutsel -selection PRIMARY -fork

        ${loadBackground}
      '';

    windowManager = {
      i3 = {
        enable = true;
        config = {
          modifier = i3Modifier;
          startup = [
            {
              command = "${autorandr} --change";
            }
          ];

          focus.followMouse = false;

          bars = [
            {
              position = "bottom";
              statusCommand = "${pkgs.i3status}/bin/i3status -c ${i3StatusConfig}";
            }
          ];

          window.titlebar = false;

          window.commands = [
            {
              command = "move down";
              criteria = { class = "Remote-viewer"; };
            }
            {
              command = "floating enable";
              criteria = { class="Hopper"; instance="hopper"; title="Hopper Disassembler v4"; };
            }
          ];

          keybindings = with config.xsession.windowManager.i3.config; mkOptionDefault {

            # vim style navigation
            "${modifier}+j" = "focus down";
            "${modifier}+h" = "focus left";
            "${modifier}+l" = "focus right";
            "${modifier}+k" = "focus up";

            "${modifier}+Shift+j" = "move down";
            "${modifier}+Shift+h" = "move left";
            "${modifier}+Shift+l" = "move right";
            "${modifier}+Shift+k" = "move up";

            "${modifier}+c" = "split h";
            "${modifier}+a" = "focus parent";

            # Arrow keys move workspaces
            "${modifier}+Down" = "move workspace to output down";
            "${modifier}+Left" = "move workspace to output left";
            "${modifier}+Right" = "move workspace to output right";
            "${modifier}+Up" = "move workspace to output up";

            "${modifier}+Shift+Down" = "move container to output down";
            "${modifier}+Shift+Left" = "move container to output left";
            "${modifier}+Shift+Right" = "move container to output right";
            "${modifier}+Shift+Up" = "move container to output up";

            # locking and suspending
            "${modifier}+o" = "exec --no-startup-id ${lockCmd}";
            "${modifier}+p" = "exec --no-startup-id ${lockSuspend}";
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
      xautolockExtraOptions = [
        "-corners 000-"
      ];
    };
  };

  xresources.properties = {

    #
    # Color Themes
    # https://web.archive.org/web/20090130061234/http://phraktured.net/terminal-colors/
    #

    # Theme: Eight
    "*background" = "rgb:10/10/10";
    "*foreground" = "rgb:d3/d3/d3";
    "*color0" = "rgb:10/10/10";
    "*color1" = "rgb:cd/5c/5c";
    "*color2" = "rgb:2e/8b/57";
    "*color3" = "rgb:f0/e6/8c";
    "*color4" = "rgb:b0/c4/de";
    "*color5" = "rgb:ba/55/d3";
    "*color6" = "rgb:46/82/b4";
    "*color7" = "rgb:d3/d3/d3";
    "*color8" = "rgb:4d/4d/4d";
    "*color9" = "rgb:ff/6a/6a";
    "*color10" = "rgb:8f/bc/8f";
    "*color11" = "rgb:ff/fa/cd";
    "*color12" = "rgb:1e/90/ff";
    "*color13" = "rgb:db/70/93";
    "*color14" = "rgb:5f/9e/a0";
    "*color15" = "rgb:ff/ff/ff";

    # Theme: Twenty-Five
    #"*background" = "black";
    #"*foreground" = "white";
    #"*color0" = "rgb:00/00/00";
    #"*color1" = "rgb:d0/00/00";
    #"*color2" = "rgb:00/80/00";
    #"*color3" = "rgb:d0/d0/90";
    #"*color4" = "rgb:00/00/80";
    #"*color5" = "rgb:80/00/80";
    #"*color6" = "rgb:a6/ca/f0";
    #"*color7" = "rgb:d0/d0/d0";
    #"*color8" = "rgb:b0/b0/b0";
    #"*color9" = "rgb:f0/80/60";
    #"*color10" = "rgb:60/f0/80";
    #"*color11" = "rgb:e0/c0/60";
    #"*color12" = "rgb:80/c0/e0";
    #"*color13" = "rgb:f0/c0/f0";
    #"*color14" = "rgb:c0/d8/f8";
    #"*color15" = "rgb:e0/e0/e0";

    #
    # Font
    #
    "*.font" = "xft:Inconsolata Regular:family=mono:pixelsize=22:antialias=true";

    #
    # HIDPI
    #

    "Xft.dpi" = 144;
    "Xft.autohint" = false;
    "Xft.lcdfilter" = "lcddefault";
    "Xft.hintstyle" = "hintfull";
    "Xft.hinting" = true;
    "Xft.antialias" = true;
    "Xft.rgba" = "rgb";
  };

  programs.direnv.enable = true;

}
