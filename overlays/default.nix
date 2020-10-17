{ ... }:
{
  nixpkgs.overlays = [
    #
    # custom overlays
    #
    (import ./vim.nix)
    (import ./ghidra.nix)
    (import ./nixops.nix)

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
