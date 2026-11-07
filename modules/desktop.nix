{ pkgs, ... }:

# The graphical session: X, lightdm, i3, audio, fonts.
#
# Machine-specific display concerns stay out of here -- videoDrivers live in
# machines/<host>, and the per-output layout lives in users/ente.nix's autorandr
# profiles.

{
  services.xserver = {
    enable = true;

    displayManager = {
      lightdm = {
        enable = true;
        greeters.mini = {
          enable = true;
          user = "ente";
        };
      };
    };

    desktopManager = {
      xterm.enable = false;
    };

    windowManager = {
      i3.enable = true;
    };
  };

  services.displayManager.defaultSession = "none+i3";

  # Applies the matching autorandr profile on hotplug. The profiles themselves
  # are declared per-user in users/ente.nix.
  services.autorandr.enable = true;

  # rtkit is optional but recommended
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  fonts.packages = with pkgs; [
    inconsolata
    font-awesome
    font-awesome_4
    font-awesome_5
  ];

  # Some programs such as virt-viewer need this
  # meta services to store configuration / passwords
  programs.dconf.enable = true;

  # chromecast
  networking.firewall.allowedTCPPorts = [ 8010 ];
}
