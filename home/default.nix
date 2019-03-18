{ pkgs, options, config, lib, ... }:

let
  myLocation = "home";
  locations = {
    home = { lat = 46.94809; long = 7.4474437.8858; };
  };
  latlong = location: if (lib.hasAttrByPath [ location ] locations) then locations.${location} else locations.home;
in {

  programs.home-manager.enable = true;
  home.stateVersion = "18.09";

  programs.git = {
    enable = true;
    userName = "Ente";
    userEmail = "ducksource@duckpond.ch";
    signing = {
      # Note that this key needs to be imported to gpg!
      key = "5279843C73EB8029F9F6AF0EC4252D5677A319CA";
      signByDefault = true;
    };
    extraConfig = {
      log = {
        decorate = "full";
      };
      rebase = {
        autostash = true;
      };
      pull = {
        rebase = true;
      };
      stash = {
        showPatch = true;
      };
      "color \"status\"" = {
        added = "green";
        changed = "yellow bold";
        untracked = "red bold";
      };
    };
  };

  programs.ssh = {
    enable = true;
    startAgent = true;
    extraConfig = ''
      Host *
        ServerAliveInterval 60
        ControlPath ~/.ssh/master-%l-%r@%h:%p
        ControlMaster auto

      Host duckpond.ch
        Port 7410
    '';
  };

  programs.bash = {
    enableAutojump = true;
    initExtra = ''
    '';
  };

  programs.firefox = {
    # enableAdobeFlash = true; # Currently broken, 404 when trying to load flash player package
    enableIcedTea = true;
  };

  programs.vim = {
    defaultEditor = true;
    plugins = pkgs.appConfigs.vim.knownPlugins;
    extraConfig = pkgs.appConfigs.vim.vimConfig;
  };

  services = {
    redshift = {
      enable = true
      latitude = toString (latlong myLocation).lat;
      longitude = toString (latlong myLocation).long;
      tray = true;
    };
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;

    # Enable touchpad support.
    libinput.enable = true;

    monitorSection = ''
      DisplaySize 310 175
    '';

    displayManager.lightdm = {
       enable = true;
       greeters.mini = {
         enable = true;
         user = "ente";
       };
    };

    desktopManager = {
      default = "xfce";
      xterm.enable = false;
      xfce = {
        enable = true;
        noDesktop = true;
        enableXfwm = false;
      };
    };

    # Enable the I3 Desktop Environment.
    windowManager = {
      default = "i3";
      i3 = {
        enable = true;
        extraSessionCommands = ''
          autocutsel -fork
          autocutsel -selection PRIMARY -fork
        '';
      };
    };
  };
}
