{ pkgs, lib ? pkgs.lib, debug ? false, ... }:

with lib;

dir: mapAttrs' (
  name: type: {
    name = removeSuffix ".nix" name;
    value = let
      file = dir + "/${name}";
    in lib.callPackageWith (
      pkgs // {
        inherit debug;
      }
    ) file {};
  }
) (
  filterAttrs (
    name: type:
    (
      type == "directory"
      && builtins.pathExists "${toString dir}/${name}/default.nix"
    ) || (
      type == "regular"
      && hasSuffix ".nix" name
      && ! (name == "default.nix")
      && ! (name == "overlays.nix")
    )
  ) (builtins.readDir dir)
)
