{
  pkgs,
  lib ? pkgs.lib,
}: let
  ## We need to tell Eldev where to find its Emacs package.
  ELDEV_LOCAL = lib.elisp.emacsPath pkgs.emacsPackages.eldev;
in {
  inherit ELDEV_LOCAL;

  checks = import ./checks {inherit ELDEV_LOCAL pkgs;};

  overlays.default = emacsOverlay: final: prev: {
    emacsPackagesFor = emacs:
      (prev.emacsPackagesFor emacs).overrideScope
      (emacsOverlay final prev);
  };

  package = pkgs.callPackage ./package.nix {inherit ELDEV_LOCAL;};
}
