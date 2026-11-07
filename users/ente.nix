{ ... }:

# ente's home-manager config. The substance lives in ./home/ -- this file is
# just the assembly, so that what the user's environment consists of is visible
# at a glance rather than buried in 700 lines.

{
  imports = [
    ../programs/git.nix
    ../programs/neovim.nix
    ../programs/claude-sandbox.nix

    ./home/packages.nix
    ./home/terminal.nix
    ./home/browser.nix
    ./home/desktop.nix
    ./home/vscode.nix
    ./home/services.nix
  ];

  programs.home-manager.enable = true;
  programs.direnv.enable = true;

  fonts.fontconfig.enable = true;

  home.stateVersion = "22.11";
}
