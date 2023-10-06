{config, ...}: {
  project = {
    name = "{{project.name}}";
    summary = "{{project.summary}}";
  };

  editorconfig.enable = true;

  programs = {
    direnv.enable = true;
    # This should default by whether there is a .git file/dir (and whether it’s
    # a file (worktree) or dir determines other things – like where hooks
    # are installed.
    git.enable = true;
    treefmt = {
      enable = true;
      programs = {
        ## Haskell linter
        hlint.enable = true;
        ## Haskell formatter
        ormolu.enable = true;
      };
    };
  };

  services = {
    flakehub.enable = true;
    garnix = {
      enable = true;
      builds.exclude = [
        # TODO: Remove once garnix-io/garnix#285 is fixed.
        "homeConfigurations.x86_64-darwin-${config.project.name}-example"
      ];
    };
    github = {
      enable = true;
      ignores = [
        # Cabal build
        "dist-newstyle"
      ];
    };
    renovate.enable = true;
  };
}
