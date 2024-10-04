{
  config,
  lib,
  ...
}: {
  imports = [
    ./..
  ];

  programs.git.ignores = [
    # Compiled
    "*.elc"
    # Packaging
    "/.eldev"
  ];

  ## See the file for why this needs to force a different version.
  project.file.".dir-locals.el".source = ./.dir-locals.el;
  ## In elisp repos, we prefer Org over Markdown, so we don’t need this
  ## formatter.
  programs.treefmt.programs.prettier.enable = lib.mkForce false;
  programs.vale = {
    excludes = [
      "*.el"
      "./Eldev"
    ];
    vocab.${config.project.name}.accept = [
      "Eldev"
    ];
  };
}
