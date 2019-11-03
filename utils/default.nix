{ pkgs, ... }:
{
  writeLoggedScript = pkgs.callPackage ./writeLoggedScript.nix {};
}
