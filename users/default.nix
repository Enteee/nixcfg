{ pkgs, options, config, lib, ... }:

let
  home-manager = builtins.fetchGit {
    url = "https://github.com/rycee/home-manager.git";
    rev = "dd94a849df69fe62fe2cb23a74c2b9330f1189ed";
    ref = "release-18.09";
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
    ];
    initialPassword = "gggggg";
    createHome = true;
    packages = [
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
      pkgs.blueman
      pkgs.mutt
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

      pkgs.manpages

      pkgs.virtmanager

      pkgs.mine.dobi
    ];
  };

  home-manager.users.ente = { ... }: {
    imports = [
      ./ente.nix
    ]; 
  };

}
