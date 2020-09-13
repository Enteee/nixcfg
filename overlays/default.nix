{ ... }:
{
  nixpkgs.overlays = [
    #
    # custom overlays
    #
    (import ./vim.nix)

    #
    # add own packages
    #
    (
      self: super: {
        mine = self.callPackage ../pkgs { };
      }
    )
  ];
}
