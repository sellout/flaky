### All available options for this file are listed in
### https://sellout.github.io/project-manager/options.xhtml
{config, ...}: {
  project = {
    name = "flaky";
    summary = "Shared configuration for dev environments";
  };

  ## dependency management
  services.renovate.enable = true;

  ## development
  programs = {
    direnv.enable = true;
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
    treefmt.enable = true;
    vale = {
      enable = true;
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

  ## publishing
  services.flakehub.enable = true;
  services.flakestry.enable = true;
  services.github.enable = true;
  services.github.settings.repository.topics = [
    "development"
    "nix-flakes"
  ];
}
