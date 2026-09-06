{ pkgs, config, lib, inputs, ... }:

let
  autorandr = lib.getExe pkgs.autorandr;
  xrdb = lib.getExe' pkgs.xrdb "xrdb";
  cat = lib.getExe' pkgs.coreutils "cat";
  i3-msg = lib.getExe' pkgs.i3 "i3-msg";
  feh-cmd = lib.getExe pkgs.feh;

  myLocation = "home";
  locations = {
    home = { lat = 46.94809; long = 7.4474437; };
  };
  latlong = location: if (lib.hasAttrByPath [ location ] locations) then locations.${location} else locations.home;

  i3Modifier = "Mod4";

  background = ./backgrounds/raven-background.jpg;

  firefoxAddons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};

  lockCmd = "${lib.getExe pkgs.i3lock} --color 000000";
  lockSuspend = pkgs.writeShellScript "lockAndSuspend.sh" ''
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

  loadBackground = pkgs.writeShellScript "load-background.sh" ''
    if [ -e $HOME/.background-image ]; then
      ${feh-cmd} --bg-scale $HOME/.background-image
    fi
  '';

in {

  imports = [
    ../programs/git.nix
    ../programs/neovim.nix
  ];

  fonts.fontconfig.enable = true;

  home = {

    file.".background-image".source = background;

    # Disable Vertical Synchronization: DisplayLink has
    # problems when vsync is enabled.
    # https://github.com/DisplayLink/evdi/issues/186
    file.".drirc".text = ''
      <device screen="0" driver="dri2">
        <application name="Default">
          <option name="vblank_mode" value="0"/>
        </application>
      </device>
      '';

    packages = with pkgs; [
      man-pages

      bitwarden-desktop
      bitwarden-cli

      arandr

      nixpkgs-review
      nixpkgs-fmt

      bc
      jq

      adwaita-icon-theme

      aspell
      aspellDicts.en
      aspellDicts.de
      languagetool

      thunderbird
      pinentry-qt

      spotify
      vlc

      pavucontrol
      easyeffects

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
      hexedit

      pastebinit

      virt-manager
      virt-viewer

      shellcheck

      binutils
      dnsutils

      lutris
      discord

      qFlipper

      gocryptfs
      mullvad-vpn

      cachix
      devenv

      openvpn

      claude-code
    ];
  };


  programs = {
    home-manager.enable = true;

    bash = {
      enable = true;
      initExtra = ''
        if [ ! -z "''${SHELL_NAME}" ]; then
          export PS1="\e[0;31m(''${SHELL_NAME})\e[m ''${PS1}"
        fi

        if [ ! -z ''${ASCIINEMA_REC+x} ]; then
          export PS1="$ "
        fi

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
      fonts = [];
      scroll.bar.enable = false;
      extraConfig = {
        "saveLines" = 1000;
        "secondaryScroll" = "off";
        "shading" = 20;

        "scrollTtyOutput" = false;
        "scrollWithBuffer" = true;
        "scrollTtyKeypress" = true;

        "perl-ext" = "default,matcher";
        "url-launcher" = lib.getExe pkgs.firefox;
        "matcher.button" = 2;

        "perl-ext-common" = "autocomplete-ALL-the-things,font-size";

        "keysym.M-C-slash" = "perl:aAtt:word-complete";
        "keysym.M-question" = "perl:aAtt:fuzzy-complete";
        "keysym.M-quotedbl" = "perl:aAtt:undo";

        "keysym.C-Up" = "font-size:increase";
        "keysym.C-Down" = "font-size:decrease";
        "keysym.C-S-Up" = "font-size:incglobal";
        "keysym.C-S-Down" = "font-size:decglobal";
        "keysym.C-equal" = "font-size:reset";
        "keysym.C-slash" = "font-size:show";
      };
    };

    firefox = {
      enable = true;

      # nixpkgs' firefox wrapper hard-sets MOZ_LEGACY_PROFILES=1, which makes
      # Firefox prefer ~/.mozilla/firefox and ignore configPath below. Unset it
      # so the profile stays in $XDG_CONFIG_HOME.
      package = pkgs.firefox.overrideAttrs (old: {
        makeWrapperArgs = (old.makeWrapperArgs or [ ])
          ++ [ "--unset" "MOZ_LEGACY_PROFILES" ];
      });

      # Not the default until home.stateVersion >= "26.05"; the profile
      # directory was moved from ~/.mozilla/firefox to match.
      # Native messaging hosts stay in ~/.mozilla/native-messaging-hosts.
      configPath = ".config/mozilla/firefox";
      profiles.default = {

        extensions.packages = with firefoxAddons; [
          noscript
          bitwarden
          tree-style-tab
          privacy-badger
          consent-o-matic
        ];

        # Enable the declaratively installed extensions without having
        # to confirm each one of them manually.
        settings = {
          "extensions.autoDisableScopes" = 0;
        };

        userChrome = ''
          #TabsToolbar {
            visibility: collapse !important;
            margin-bottom: 21px !important;
          }

          #sidebar-box[sidebarcommand="treestyletab_piro_sakura_ne_jp-sidebar-action"] #sidebar-header {
            visibility: collapse !important;
          }
          '';
      };
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
            DVI-I-1-1 = "00ffffffffffff004c2d670b3336333032180103803c22782a9791a556549d250e5054bfef80714f81c0810081809500a9c0b3000101023a801871382d40582c450056502100001e011d007251d01e206e28550056502100001e000000fd00324b1e5111000a202020202020000000fc00533237443339300a202020202001d402031af14690041f130312230907078301000066030c00100080011d00bc52d01e20b828554056502100001e8c0ad090204031200c4055005650210000188c0ad08a20e02d10103e9600565021000018000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000061";
            DVI-I-2-2 = "00ffffffffffff004c2d670b3336333006190103803c22782a9791a556549d250e5054bfef80714f81c0810081809500a9c0b3000101023a801871382d40582c450056502100001e011d007251d01e206e28550056502100001e000000fd00324b1e5111000a202020202020000000fc00533237443339300a202020202001ff02031af14690041f130312230907078301000066030c00100080011d00bc52d01e20b828554056502100001e8c0ad090204031200c4055005650210000188c0ad08a20e02d10103e9600565021000018000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000061";
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
              primary = true;
              rate = "60.00";
            };
            DVI-I-2-2 = {
              enable = true;
              mode = "1920x1080";
              gamma = "1.0:0.667:0.455";
              position = "1920x0";
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

      };
    };

    vscode = {
      enable = true;
      profiles.default = {
        userSettings = {
          telemetry.telemetryLevel = "off";
          java.home = "${pkgs.jdk}/lib/openjdk";
          python.defaultInterpreterPath = "${pkgs.python3.withPackages(ps: with ps; [
            pylint
            autopep8
          ])}/bin/python3";
          files.exclude = {
            "**/.classpath" = true;
            "**/.project" = true;
            "**/.settings" = true;
            "**/.factorypath" = true;
          };
          cmake.configureOnOpen = true;
          editor.minimap.enabled = false;
        };

        extensions = (with pkgs.vscode-extensions; [
          ms-vscode.cpptools
          ms-vscode.cmake-tools
          xaver.clang-format

          ms-python.python
          ms-python.vscode-pylance
          mkhl.direnv

          vscjava.vscode-java-pack

          arrterian.nix-env-selector
        ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        ]);
      };
    };

  };

  xsession = {

    enable = true;

    numlock.enable = true;

    initExtra = ''
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
              statusCommand = "${lib.getExe pkgs.i3status} -c ${i3StatusConfig}";
            }
          ];

          window.titlebar = false;

          window.commands = [
            {
              command = "move down";
              criteria = { class = "Remote-viewer"; };
            }
          ];

          floating.criteria = [
              { class="^Steam$"; instance="^Steam$"; }
          ];

          keybindings = with config.xsession.windowManager.i3.config; lib.mkOptionDefault {

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

            "${modifier}+Down" = "move workspace to output down";
            "${modifier}+Left" = "move workspace to output left";
            "${modifier}+Right" = "move workspace to output right";
            "${modifier}+Up" = "move workspace to output up";

            "${modifier}+Shift+Down" = "move container to output down";
            "${modifier}+Shift+Left" = "move container to output left";
            "${modifier}+Shift+Right" = "move container to output right";
            "${modifier}+Shift+Up" = "move container to output up";

            "${modifier}+o" = "exec --no-startup-id ${lockCmd}";
            "${modifier}+p" = "exec --no-startup-id ${lockSuspend}";
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
      xautolock.extraOptions = [
        "-corners 000-"
      ];
    };
  };

  xresources.properties = {
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

    "*.font" = "xft:Inconsolata Regular:family=mono:pixelsize=22:antialias=true";

    "Xft.dpi" = 144;
    "Xft.autohint" = false;
    "Xft.lcdfilter" = "lcddefault";
    "Xft.hintstyle" = "hintfull";
    "Xft.hinting" = true;
    "Xft.antialias" = true;
    "Xft.rgba" = "rgb";
  };

  programs.direnv.enable = true;

  home.stateVersion = "22.11";
}
