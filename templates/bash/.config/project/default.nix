{config, ...}: {
  project = {
    name = "{{project.name}}";
    summary = "{{project.summary}}";
  };

  ## dependency management
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
    treefmt = {
      enable = true;
      ## Shell linter
      programs.shellcheck.enable = true;
      ## Shell formatter
      programs.shfmt.enable = true;
    };
    vale = {
      enable = true;
      excludes = [
        "./.github/settings.yml"
      ];
    };
  };

  ## CI
  services.garnix = {
    enable = true;
    ## TODO: Remove once garnix-io/garnix#285 is fixed.
    builds.exclude = ["homeConfigurations.x86_64-darwin-example"];
  };

  ## publishing
  services = {
    flakehub.enable = true;
    github.enable = true;
  };
}
