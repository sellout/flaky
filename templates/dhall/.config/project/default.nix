{
  config,
  flaky,
  lib,
  pkgs,
  supportedSystems,
  ...
}: {
  project = {
    name = "{{project.name}}";
    summary = "{{project.summary}}";

    devPackages = [
      pkgs.dhall
      pkgs.dhall-docs
      pkgs.dhall-lsp-server
    ];
  };

  ## dependency managerment
  services.renovate.enable = true;

  ## development
  programs = {
    direnv.enable = true;
    # This should default by whether there is a .git file/dir (and whether it’s
    # a file (worktree) or dir determines other things – like where hooks
    # are installed.
    git.enable = true;
  };

  ## formatting
  editorconfig.enable = true;
  programs = {
    treefmt.enable = true;
    vale.enable = true;
  };
  project.file.".dir-locals.el".source = ../emacs/.dir-locals.el;

  ## CI
  services.garnix.enable = true;

  ## publishing
  services.flakehub.enable = true;
  services.github.enable = true;
  services.github.settings.repository.topics = ["library"];
}
