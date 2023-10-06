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
      programs.dhall = {
        enable = true;
        lint = true;
      };
      settings.formatter.dhall.includes = ["dhall/*"];
    };
  };

  services = {
    flakehub.enable = true;
    garnix = {
      enable = true;
      builds.exclude = [
        # TODO: Remove once garnix-io/garnix#285 is fixed.
        "homeConfigurations.x86_64-darwin-${config.project.name}-example"
      };
    };
    github = {
      enable = true;
      settings = {
        repository = {
          homepage = "https://sellout.github.io/${config.project.name}";
          topics = ["dhall" "library"];
        };
        branches.main.protection.required_status_checks.contexts =
          lib.concatMap garnixChecks [
            (sys: "homeConfig ${s}-${config.project.name}-example")
            (sys: "package default [${s}]")
            (sys: "package ${config.project.name} [${s}]")
          ];
        pages = {
          build_type = "workflow";
          source.branch = "main";
        };
      };
    };
    renovate.enable = true;
  };
}
