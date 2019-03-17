{ ... }:

{
  nixpkgs.overlays = [
    (import ../pkgs/overlays.nix)
  ];
}
