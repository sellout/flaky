{
  pkgs,
  runEmptyCommand,
  runStrictCommand,
  self,
}: let
  validate-template-with =
    pkgs.callPackage ../checks/validate-template.nix {inherit runStrictCommand self;};
in {
  inherit validate-template-with;

  ## This produces a fixed-output derivation so we can sandbox a derivation that
  ## otherwise couldn’t be. However, it uses IFD, so only use it on derivations
  ## that wouldn’t otherwise be sandboxable.
  simple = name: src: nativeBuildInputs:
    runEmptyCommand name {inherit nativeBuildInputs src;};

  validate-template = validate-template-with {};
}
