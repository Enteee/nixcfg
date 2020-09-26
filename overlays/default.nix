{ ... }:
{
  nixpkgs.overlays = [
    #
    # custom overlays
    #
    (import ./vim.nix)
    (import ./ghidra.nix)

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
