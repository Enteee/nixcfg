{ pkgs, options, config, lib, ... }:

let
  myLocation = "home";
  locations = {
    home = { lat = 46.94809; long = 7.4474437; };
  };
  latlong = location: if (lib.hasAttrByPath [ location ] locations) then locations.${location} else locations.home;
in {

  programs = {
    home-manager.enable = true;

    git = {
      enable = true;
      userName = "Ente";
      userEmail = "ducksource@duckpond.ch";
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

  };

#  programs.bash = {
#    enableAutojump = true;
#    initExtra = ''
#    '';
#  };

#  programs.firefox = {
#    # enableAdobeFlash = true; # Currently broken, 404 when trying to load flash player package
#    enableIcedTea = true;
#  };

  services = {
    redshift = {
      enable = true;
      latitude = toString (latlong myLocation).lat;
      longitude = toString (latlong myLocation).long;
    };
  };

}
