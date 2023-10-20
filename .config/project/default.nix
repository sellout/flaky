{config, lib, pkgs, ...}: {
  project = {
    name = "flaky";
    summary = "Templates for dev environments";

    ## This defaults to `true`, because I want most projects to be
    ## contributable-to by non-Nix users. However, Nix-specific projects can
    ## lean into Project Manager and avoid committing extra files.
    commit-by-default = lib.mkForce false;
  };

  ## dependency management
  services.renovate.enable = true;

  ## development
  programs = {
    direnv = {
      enable = true;
      ## See the reasoning on `project.commit-by-default`.
      commit-envrc = false;
    };
    git = {
      # TODO: This should default by whether there is a .git file/dir (and
      #       whether it’s a file (worktree) or dir determines other things –
      #       like where hooks are installed.
      enable = true;
      ignoreRevs = [
        "dc0697c51a4ed5479d3ac7fcb304478729ab2793" # nix fmt
      ];
    };
  };

  ## formatting
  editorconfig.enable = true;
  programs = {
    treefmt = {
      enable = true;
      ## NB: This is normally "flake.nix", but since this repo contains
      ##     sub-flakes, we use the .git/config because it’s unique.
      projectRootFile = lib.mkForce ".git/config";
      programs = {
        ## Shell linter
        shellcheck.enable = true;
        ## Shell formatter
        shfmt.enable = true;
        ## FIXME: Shouldn’t have to duplicate this from base config.
        alejandra.enable = true;
        prettier.enable = true;
        shfmt.indent_size = null;
      };
      settings = {
        formatter.shfmt.includes = ["scripts/*"];
        ## Each template has its own formatter that is run during checks, so
        ## we don’t check them here. The `*/*` is needed so that we don’t miss
        ## formatting anything in the templates directory that is not part of
        ## a specific template.
        global.excludes = ["templates/*/*"];
      };
    };
    vale = {
      enable = true;
      coreSettings.Vocab = "flaky";
      ## This is a personal repository.
      formatSettings."*"."Microsoft.FirstPerson" = "NO";
      vocab.flaky.accept = config.programs.vale.vocab.base.accept ++ [
        "Dhall"
        "EditorConfig"
        ## Separated because “Editorconfig” and “editorConfig” aren’t valid.
        "editorconfig"
        "Eldev"
        "envrc"
        "fmt"
        "Probot"
        "shfmt"
      ];
      excludes = [
        ## These either use Vale or not themselves.
        "./templates/*"
        ## TODO: Not sure how to tell Vale that these are code files.
        "./scripts/*"
        ## TODO: Have a general `ignores` list that we can process into
        ##       gitignores, `find -not` lists, etc.
        "./.github/settings.yml"
        "./garnix.yaml"
        "./renovate.json"
      ];
    };
  };

  ## CI
  services.garnix = {
    enable = true;
    builds.exclude = [
      ## TODO: These currently fail because they need Internet access.
      "checks.*.bash-template-validity"
      "checks.*.c-template-validity"
      "checks.*.default-template-validity"
      "checks.*.dhall-template-validity"
      "checks.*.emacs-lisp-template-validity"
      "checks.*.haskell-template-validity"
      "checks.*.nix-template-validity"
    ];
  };

  ## publishing
  services = {
    flakehub.enable = true;
    github = {
      enable = true;
      settings.repository.topics = ["development" "nix-flakes" "nix-templates"];
    };
  };
}
