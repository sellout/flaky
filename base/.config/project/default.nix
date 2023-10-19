## This is the foundational config for all my projects. Each one uses this
## module and overrides what it wants.
##
## NB: This doesn’t enable any modules, simply configures them. The templates
##     (and concrete projects) enable the modules, making it easy to see which
##     ones are applied to any given project.
{lib, pkgs, ...}: {
  project = {
    authors = [lib.maintainers.sellout];
    license = "AGPL-3.0-or-later";
    ## Packages to install in the devShells that reference projectConfiguration.
    packages = [
      ## language servers
      pkgs.nil # Nix
      pkgs.nodePackages.bash-language-server
    ];
  };

  imports = [
    ## tooling
    ./direnv.nix
    ./git.nix
    ./mustache.nix
    ./shellcheck
    ./treefmt.nix
    ./vale.nix
    ## services
    ./flakehub.nix
    ./garnix.nix
    ./github.nix
    ## editors
    ./editorconfig.nix
    ./emacs
    ## other
    ./hacktoberfest.nix
  ];

  programs.project-manager.enable = true;
}
