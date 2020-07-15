{ ... }:
{
  programs.git = {
    enable = true;
    userName = "Ente";
    userEmail = "ducksource@duckpond.ch";
    extraConfig = {
      log = {
        decorate = "full";
      };
      pull = {
        rebase = false;
      };
      rebase = {
        autostash = true;
      };
      stash = {
        showPatch = true;
      };
      "color \"status\"" = {
        added = "green";
        changed = "yellow bold";
        untracked = "red bold";
      };
    };
  };

}
