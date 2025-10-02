{
  pkgs,
  runEmptyCommand,
  self,
}: let
  ## This produces a fixed-output derivation so we can sandbox a derivation that
  ## otherwise couldn’t be. However, it uses IFD, so only use it on derivations
  ## that wouldn’t otherwise be sandboxable.
  simple = name: src: nativeBuildInputs:
    runEmptyCommand name {inherit nativeBuildInputs src;};
in {
  inherit simple;

  validate-template =
    pkgs.callPackage ../checks/validate-template.nix {inherit self simple;};
}
