{ stdenv, buildEnv, fetchurl }:

let
  version = "0.12.0";
  drv = stdenv.mkDerivation {
    name = "dobi-${version}";

    src = fetchurl {
      url = "https://github.com/dnephin/dobi/releases/download/v${version}/dobi-Linux";
      sha256 = "1ip1nm5ma6hzj35gwrs41gxbc7rsgf7kddwfl5mbxz53h0rr7gqh";
    };

    meta = {
      description = "A build automation tool for Docker applications";
      homepage    = "https://dnephin.github.io/dobi/";
      platforms   = with stdenv.lib.platforms; linux;
      license     = stdenv.lib.licenses.apache2;
      maintainers = [ stdenv.lib.maintainers.ente ];
    };

    phases = ["installPhase" "patchPhase"];

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/dobi
      chmod +x $out/bin/dobi
    '';
  };
in
  buildEnv { name = drv.name; paths = [ drv ]; }
