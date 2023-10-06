{lib, pkgs, ...}: {
  project = {
    name = "flaky";
    summary = "Templates for dev environments";
    ## This defaults to `true`, because I want most projects to be
    ## contributable-to by non-Nix users. However, Nix-specific projects can
    ## lean into Project Manager and avoid committing extra files.
    commit-by-default = lib.mkForce false;
  };

  editorconfig.enable = true;

  programs = {
    direnv = {
      enable = true;
      ## See the reasoning on `project.commit-by-default`.
      commit-envrc = false;
    };
    # This should default by whether there is a .git file/dir (and whether it’s
    # a file (worktree) or dir determines other things – like where hooks
    # are installed.
    git = {
      enable = true;
      ignoreRevs = [
        "dc0697c51a4ed5479d3ac7fcb304478729ab2793" # nix fmt
      ];
    };
    treefmt = {
      enable = true;
      ## NB: This is normally "flake.nix", but since this repo contains
      ##     sub-flakes, we use the .git/config because it is unique.
      projectRootFile = ".git/config";
      programs = {
        ## Shell linter
        shellcheck.enable = true;
        ## Shell formatter
        shfmt = {
          enable = true;
          ## NB: This has to be unset to allow the .editorconfig
          ##     settings to be used. See numtide/treefmt-nix#96.
          indent_size = null;
        };
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
      vocab.flaky.accept = [
        "Dhall"
        "direnv"
        "EditorConfig"
        "editorconfig"
        "Eldev"
        "envrc"
        "fmt"
        "[Nn]ix"
        "Probot"
        "ShellCheck"
        "shfmt"
      ];
      excludes = [
        ## We skip licenses because they are written by lawyers, not by us.
        "*/LICENSE"
        ## These either use Vale or not themselves.
        "./templates/*"
        ## TODO: Not sure how to tell Vale that these are code files.
        "./scripts/*"
        ## TODO: Have a general `ignores` list that we can process into
        ##       gitignores, `find -not` lists, etc.
        "./.cache/*"
        "./.github/settings.yml"
        "./.github/workflows/flakehub-publish.yml"
        "./.vale.ini"
        "./flake.lock"
        "./garnix.yaml"
        "./renovate.json"
        "*/Eldev"
        "*.nix"
      ];
    };
  };

  services = {
    flakehub.enable = true;
    garnix = {
      enable = true;
      builds.exclude = [
        ## TODO: These currently fail because they need Internet access.
        "checks.*.bash-template-validity"
        "checks.*.c-template-validity"
        "checks.*.default-template-validity"
        "checks.*.dhall-template-validity" # I don’t know why this one fails
        "checks.*.nix-template-validity"
        ## TODO: Fails because it doesn’t work in a sandbox.
        "checks.*.vale"
      ];
    };
    github = {
      enable = true;
      settings.repository.topics = ["development" "nix-flakes" "nix-templates"];
    };
    renovate.enable = true;
  };
}
