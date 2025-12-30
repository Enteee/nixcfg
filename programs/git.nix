{ ... }:
{
  programs.git = {

    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = "Ente";
        email = "ducksource@duckpond.ch";
      };

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

    signing = {
      key = "Enteee <ducksource@duckpond.ch>";
      signByDefault = true;
    };

  };

}
