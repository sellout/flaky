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
  };
}
