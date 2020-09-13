{ callPackage, ... }:
let
  utils = callPackage ../utils {};
in utils.callPackageAllSubdirs ./.
