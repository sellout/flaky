### All available options for this file are listed in
### https://sellout.github.io/project-manager/options.xhtml
{
  imports = [
    ./..
  ];

  ## This defaults to `true`, because I want most projects to be
  ## contributable-to by non-Nix users. However, Nix-specific projects can lean
  ## into Project Manager and avoid committing extra files.
  project.commit-by-default = false;

  ## See the reasoning on `project.commit-by-default`.
  programs.direnv.commit-envrc = false;
}
