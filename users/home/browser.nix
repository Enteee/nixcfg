{ pkgs, inputs, ... }:

let
  firefoxAddons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  programs.firefox = {
    enable = true;

    # Pinned explicitly: home-manager 26.05 changed this default to
    # $XDG_CONFIG_HOME/mozilla/firefox, but nixpkgs' wrapper hard-sets
    # MOZ_LEGACY_PROFILES=1, which makes Firefox read ~/.mozilla/firefox and
    # ignore the XDG path entirely. Unsetting that variable is not an option:
    # it switches on Firefox's per-installation "dedicated profile" feature,
    # which keys off the installation path, and on NixOS that store path
    # changes on every Firefox update -- so each update would silently adopt
    # a fresh, empty profile.
    configPath = ".mozilla/firefox";

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
}
