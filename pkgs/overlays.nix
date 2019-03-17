self: super: {
  mine = import ./default.nix {
    pkgs = self;
  };
}
