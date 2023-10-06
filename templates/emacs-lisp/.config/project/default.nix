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
    git = {
      enable = true;
      ignores = [
        # Compiled
        "*.elc"
        # Packaging
        "/.eldev"
      ];
    };
    treefmt = {
      enable = true;
      ## In elisp repos, we prefer Org over Markdown, so we don’t need this
      ## formatter.
      programs.prettier.enable = lib.mkForce false;
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
      settings = {
        branches.main.protection.required_status_checks.contexts =
          lib.concatMap garnixChecks [
            (sys: "check elisp-doctor [${sys}]")
            (sys: "check elisp-lint [${sys}]")
            (sys: "homeConfig ${sys}-${config.project.name}-example")
            (sys: "package default [${sys}]")
            (sys: "package emacs-${config.project.name} [${sys}]")
          ];
      };
    };
    renovate.enable = true;
  };
}
