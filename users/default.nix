{ pkgs, options, config, lib, ... }:

let
  home-manager = builtins.fetchGit {
    url = "https://github.com/rycee/home-manager.git";
    rev = "76ba4bedff2a27b74b7208ead2f9e1ca9594ff39";
    ref = "release-19.03";
  };
in
{
  imports = [
    "${home-manager}/nixos"
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

      rxvt_unicode-with-plugins
      urxvt_font_size

      aspell
      aspellDicts.en
      languagetool

      thunderbird
      gnupg

      feh
      spotify
      evince
      pwgen
      gimp
      inkscape
      unzip
      firefox
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
