{pkgs, ...}: {
  programs.shellcheck.settings.source = ./rc;
  project.packages = [pkgs.shellcheck];
}
