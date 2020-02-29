{ pkgs, options, config, lib, ... }:

let
  home-manager = (import <home-manager> {});

  custom-rxvt-unicode = pkgs.rxvt-unicode.override {
    configure = { availablePlugins, ... }: {
      plugins = with availablePlugins; [
        autocomplete-all-the-things
        font-size
      ];
    };
  };

in
{
  imports = [
    home-manager.nixos
  ];

  home-manager.users.root = { ... }: {
    imports = [
      ./root.nix
    ];
  };

  users.users.ente = {
    isNormalUser = true;

    uid = 1000;
    extraGroups = [
      "wheel"
      "docker"
      "libvirtd"
      "networkmanager"
      "wireshark"
      "adbusers"
    ];
    initialPassword = "gggggg";
    createHome = true;
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
      firefox
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

      mine.dobi
      mine.rmapi
    ];
  };

  home-manager.users.ente = { ... }: {
    imports = [
      ./ente.nix
    ]; 
  };

}
