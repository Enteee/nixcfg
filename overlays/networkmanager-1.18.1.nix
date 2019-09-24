self: super:

{
  networkmanager = super.networkmanager.overrideAttrs (old: with super.networkmanager; rec {
    version = "1.18.1";
    src = super.fetchurl {
      url = "mirror://gnome/sources/NetworkManager/${stdenv.lib.versions.majorMinor version}/NetworkManager-${version}.tar.xz";
      sha256 = "07vg2ryyjaxs5h8kmkwqhk4ki750c4di98g0i7h7zglfs16psiqd";
    };
  });
}
