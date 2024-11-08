{
  ELDEV_LOCAL,
  pkgs,
}: {
  doctor = pkgs.callPackage ./doctor.nix {inherit ELDEV_LOCAL;};
  lint = pkgs.callPackage ./lint.nix {inherit ELDEV_LOCAL;};
}
