{config, lib, pkgs, ...}: {
  project = {
    file.".shellcheckrc" = {
      ## TODO: Should be able to make this `"store"`.
      minimum-persistence = "worktree";
      source = ./rc;
    };
    packages = [pkgs.shellcheck];
  };
}
