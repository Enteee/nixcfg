{ callPackage, ... }:
{
  writeLoggedScript = callPackage ./writeLoggedScript.nix {};
  callPackageAllSubdirs = callPackage ./callPackageAllSubdirs.nix {};
}
