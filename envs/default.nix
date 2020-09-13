{ pkgs, lib, home, config, ... }:
with lib;
let
  cfg = config.envs;

  envDirs = filterAttrs (
    name: type: (
      type == "directory"
    )
  ) (builtins.readDir ./.);

  envs = mapAttrs (
    name: type: rec {
      path = pkgs.copyPathToStore (./. + ("/" + name));

      scripts = [

        (
          pkgs.writeShellScriptBin "env-${name}" ''
            nix-shell "${path}"
          ''
        )

        (
          pkgs.writeShellScriptBin "env-${name}-init" ''
            echo "use_nix ${path}" > .envrc
          ''
        )

        (
          pkgs.writeShellScriptBin "env-${name}-cc" ''
            cp -ri "${path}/." .
            (
              cd "${path}" && find -print0
            ) | xargs -0 -n1 chmod u+w
          ''
        )

      ];
    }
  ) envDirs;

  packages = builtins.concatLists (
    mapAttrsToList (
      k: v: v.scripts
    ) envs
  );

in {

  options = {
    envs = {
      enable = mkEnableOption "support for custom environments";
    };
  };

  config = mkIf cfg.enable {
    home.packages = packages;
  };
}
