{
  pkgs,
  runEmptyCommand,
  self,
}: let
  simple = name: src: nativeBuildInputs:
    runEmptyCommand name {inherit nativeBuildInputs src;};
in {
  inherit simple;

  validate-template =
    pkgs.callPackage ../checks/validate-template.nix {inherit self simple;};
}
