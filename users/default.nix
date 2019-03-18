{ ... }:

let
  home-manager = builtins.fetchGit {
    url = "https://github.com/rycee/home-manager.git";
    rev = "dd94a849df69fe62fe2cb23a74c2b9330f1189ed";
    ref = "release-18.09";
  };
in
{
  imports = [
    "${home-manager}/nixos"
  ];

  users.users.ente = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "networkmanager" "wheel"];
    initialPassword = "gggggg";
    createHome = true;
  };

  home-manager.users.ente = { ... }: {
    imports = [
      ./ente.nix
    ]; 
  };
}
