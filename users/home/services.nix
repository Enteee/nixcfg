{ pkgs, lib, ... }:

# User services.
#
# screen-locker lives here rather than next to the i3 lock keybindings, and
# desktop.nix reads `config.services.screen-locker.lockCmd` back out of the
# module system instead of duplicating the command. One source of truth.

let
  myLocation = "home";
  locations = {
    home = {
      lat = 46.94809;
      long = 7.4474437;
    };
  };
  latlong =
    location:
    if (lib.hasAttrByPath [ location ] locations) then locations.${location} else locations.home;
in
{
  services.redshift = {
    enable = true;
    tray = true;
    latitude = toString (latlong myLocation).lat;
    longitude = toString (latlong myLocation).long;
    temperature.night = 2500;
  };

  services.screen-locker = {
    enable = true;
    lockCmd = "${lib.getExe pkgs.i3lock} --color 000000";
    xautolock.extraOptions = [
      "-corners 000-"
    ];
  };
}
