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
    name: type: pkgs.stdenv.mkDerivation {
      inherit name;

      src = ./. + ("/" + name);

      phases = [
        "unpackPhase"
        "installPhase"
      ];

      installPhase = ''
        mkdir -p $out/bin

        out_env="$out/env/${name}"
        mkdir -p "$out_env"

        cp -r . "$out_env"

        cat > "$out/bin/env-${name}" <<EOF
        #!${pkgs.runtimeShell}
        nix-shell "$out_env"
        EOF

        cat > "$out/bin/env-${name}-init" <<EOF
        #!${pkgs.runtimeShell}
        echo "use_nix $out_env" > .envrc
        EOF

        cat > "$out/bin/env-${name}-cc" <<EOF
        #!${pkgs.runtimeShell}
        cp -ri "$out_env/." .
        (
          cd "$out_env" && find -print0
        ) | xargs -0 -n1 chmod u+w
        EOF

        chmod -R ugo+x $out/bin
        '';
    }
  ) envDirs;

  packages = mapAttrsToList (
    k: v: v
  ) envs;

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
