### This is the foundational config for all my projects. Each one uses this
### module and overrides what it wants.
###
### NB: This doesn’t enable any modules, simply configures them. The templates in
###     flaky-environments (and concrete projects) enable the modules, making it
###     easy to see which ones are applied to any given project.
###
### All available options for this file are listed in
### https://sellout.github.io/project-manager/options.xhtml
{
  lib,
  pkgs,
  ...
}: {
  project = {
    authors = [lib.maintainers.sellout];
    license = lib.mkDefault "AGPL-3.0-or-later";

    ## Packages to install in the devShells that reference projectConfiguration.
    devPackages =
      [
        ## language servers
        pkgs.nil # Nix
      ]
      ++ (
        ## NB: pnpm (a dependency of bash-language-server) fails to build on
        ##     i686-linux.
        if pkgs.system == "i686-linux"
        then []
        else [pkgs.nodePackages.bash-language-server]
      );

    ## NB: This allows non-Nix users to contribute to the project.
    commit-by-default = lib.mkDefault true;

    stateVersion = 0;
  };

  imports = [
    ## tooling
    ./direnv.nix
    ./git.nix
    ./shellcheck.nix
    ./treefmt.nix
    ./vale.nix
    ## services
    ./flakehub.nix
    ./garnix.nix
    ./github.nix
    ./nix-ci.nix
    ./renovate.nix
    ## editors
    ./editorconfig.nix
    ./emacs
    ## other
    ./hacktoberfest.nix
  ];

  programs.project-manager.enable = true;

  ## For most modules, `enable` is set at the individual project level. However,
  ## these are enabled globally on GitHub, so this just ensures that we
  ## constrain them with the appropriate config.
  services.garnix.enable = true;
  services.nix-ci.enable = true;
}
