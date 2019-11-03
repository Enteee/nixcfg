{ callPackage, fetchFromGitHub, buildGoPackage, buildEnv, stdenv}:

let
  pname = "rmapi";
  repo = fetchFromGitHub {
    owner = "Enteee";
    repo = pname;
    rev = "65c869f7566ce66a517509219c8ba9f58483808e";
    sha256 = "sha256:0limyj7dim0vr3c357zbhvhrm3jg3jjiv95fb0bgif3ri9f03akj";
  };
  drv = callPackage "${repo}/derivation.nix" {
    buildGoPackage = super: buildGoPackage (super // {
      meta = super.meta // {
        maintainer = stdenv.lib.maintainers.arthur;
      };
    });
  };
in
  buildEnv { name = drv.name; paths = [ drv ]; }
