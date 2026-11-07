{ pkgs, ... }:

# User packages and the background image.

{
  home.file.".background-image".source = ../backgrounds/raven-background.jpg;

  home.packages = with pkgs; [
    man-pages

    bitwarden-desktop
    bitwarden-cli

    arandr

    nixpkgs-review
    nixfmt

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
}
