{
  config,
  flaky,
  lib,
  supportedSystems,
  ...
}: {
  project = {
    name = "{{project.name}}";
    summary = "{{project.summary}}";
  };

  ## dependency management
  services.renovate.enable = true;

  ## development
  programs = {
    direnv.enable = true;
    git.enable = true;
  };

  ## formatting
  editorconfig.enable = true;
  programs = {
    treefmt.enable = true;
    vale.enable = true;
  };

  ## CI
  services.garnix.enable = true;
  ## FIXME: Shouldn’t need `mkForce` here (or to duplicate the base contexts).
  ##        Need to improve module merging.
  services.github.settings.branches.main.protection.required_status_checks.contexts =
    lib.mkForce
    (flaky.lib.forGarnixSystems supportedSystems (sys: [
      "check elisp-doctor [${sys}]"
      "check elisp-lint [${sys}]"
      "homeConfig ${sys}-example"
      "package default [${sys}]"
      "package emacs-${config.project.name} [${sys}]"
      ## FIXME: These are duplicated from the base config
      "check formatter [${sys}]"
      "check project-manager-files [${sys}]"
      "check vale [${sys}]"
      "devShell default [${sys}]"
    ]));

  ## publishing
  services.flakehub.enable = true;
  services.github.enable = true;
}
