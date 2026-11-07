{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      nixos-hardware,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Both hosts share the same system, specialArgs and home-manager wiring;
      # only the machine directory and any nixos-hardware profile differ.
      mkSystem =
        modules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [ home-manager.nixosModules.home-manager ] ++ modules;
        };
    in
    {
      nixosConfigurations = {
        puddle = mkSystem [
          nixos-hardware.nixosModules.lenovo-thinkpad-t480s
          ./machines/puddle
        ];

        pond = mkSystem [
          ./machines/pond
        ];
      };

      # `nix fmt`. nixpkgs-fmt is deprecated upstream in favour of the RFC 166
      # formatter, which is now plain pkgs.nixfmt -- nixfmt-rfc-style is itself
      # an alias that warns on eval.
      #
      # Wrapped rather than used bare: `nix fmt` invokes the formatter with no
      # arguments when none are given, and bare nixfmt then reads stdin and
      # fails on empty input ("Bare invocation of nixfmt is deprecated"). The
      # wrapper expands a directory to the .nix files under it, skipping .git
      # and any build results.
      formatter.${system} = pkgs.writeShellApplication {
        name = "fmt";
        runtimeInputs = [
          pkgs.nixfmt
          pkgs.findutils
        ];
        text = ''
          [ "$#" -gt 0 ] || set -- .
          find "$@" \
            \( -name .git -o -name result -o -name 'result-*' \) -prune -o \
            -type f -name '*.nix' -print0 \
            | xargs -0 -r nixfmt
        '';
      };

      checks.${system} = {
        # Full builds. Note puddle can only be built *on* puddle: its
        # DisplayLink driver is a requireFile, because nixpkgs may not
        # redistribute the blob, so it has to be nix-prefetch-url'd into the
        # local store by hand. Running `nix flake check` elsewhere will fail on
        # that one derivation and nothing else.
        pond = self.nixosConfigurations.pond.config.system.build.toplevel;
        puddle = self.nixosConfigurations.puddle.config.system.build.toplevel;

        # Evaluation-only gate that works on any machine. Asking for drvPath
        # instantiates both module systems, which is what catches renamed or
        # removed options after a release bump -- but the string context has to
        # be discarded, or the path becomes a real build input and this check
        # drags in the full closure (including puddle's DisplayLink blob, which
        # cannot be fetched anywhere but puddle).
        eval =
          let
            instantiate =
              host:
              builtins.unsafeDiscardStringContext
                self.nixosConfigurations.${host}.config.system.build.toplevel.drvPath;
          in
          pkgs.runCommand "nixcfg-eval" { } ''
            {
              echo ${instantiate "pond"}
              echo ${instantiate "puddle"}
            } > $out
          '';
      };
    };
}
