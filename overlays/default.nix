{ ... }:
{
  nixpkgs.overlays = [
    (import ../pkgs/overlays.nix)
    (import ./vim.nix)
  ];
}
