{ ... }:

{
  nixpkgs.overlays = [
    (import ../pkgs/overlays.nix)
    (import ./networkmanager-1.18.1.nix)
  ];
}
