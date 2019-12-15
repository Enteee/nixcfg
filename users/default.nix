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
    packages = [
      pkgs.manpages

      pkgs.arandr

      pkgs.nixpkgs-fmt

      pkgs.jq

      pkgs.rxvt_unicode-with-plugins
      pkgs.urxvt_font_size

      pkgs.aspell
      pkgs.aspellDicts.en
      pkgs.languagetool

      pkgs.thunderbird
      pkgs.gnupg

      pkgs.feh
      pkgs.spotify
      pkgs.evince
      pkgs.pwgen
      pkgs.gimp
      pkgs.inkscape
      pkgs.unzip
      pkgs.firefox
      pkgs.asciinema
      pkgs.wireshark
      pkgs.nixops
      pkgs.jre
      pkgs.skypeforlinux
      pkgs.hopper
      pkgs.pastebinit

      pkgs.virtmanager

      pkgs.shellcheck

      pkgs.dnsutils

      pkgs.mine.dobi
      pkgs.mine.rmapi
    ];
  };

  home-manager.users.ente = { ... }: {
    imports = [
      ./ente.nix
    ]; 
  };

}
