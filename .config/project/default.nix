### All available options for this file are listed in
### https://sellout.github.io/project-manager/options.xhtml
{config, ...}: {
  project = {
    name = "flaky";
    summary = "Shared configuration for dev environments";
  };

  programs = {
    git.ignoreRevs = [
      "dc0697c51a4ed5479d3ac7fcb304478729ab2793" # nix fmt
    ];
    vale = {
      ## This is a personal repository.
      formatSettings."*"."Microsoft.FirstPerson" = "NO";
      vocab.${config.project.name}.accept = [
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
    };
  };

  services = {
    github.settings.repository.topics = [
      "development"
      "nix-flakes"
    ];
    ## Only run Renovate monthly (on the 15th). This reduces the amount of
    ## cascading Nixpkgs updates, which makes it more likely that checked out
    ## repos are on the same revision.
    renovate.settings.lockFileMaintenance = {
      ## FIXME: Should only need the `schedule` field here, but this doesn’t
      ##        currently merge properly, so need to replicate the whole
      ##        structure.
      automerge = true;
      enabled = true;
      schedule = ["* 0-4 15 * *"];
    };
  };
}
