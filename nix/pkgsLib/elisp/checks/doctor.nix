{
  ELDEV_LOCAL,
  checkedDrv,
  emacs,
  emacsPackages,
  stdenv,
  ...
}: src:
checkedDrv (stdenv.mkDerivation {
  inherit ELDEV_LOCAL src;

  name = "eldev doctor";

  nativeBuildInputs = [
    emacs
    # Emacs-lisp build tool, https://doublep.github.io/eldev/
    emacsPackages.eldev
  ];

  buildPhase = ''
    runHook preBuild
    ## TODO: Currently needed to make a temp file in
    ##      `eldev--create-internal-pseudoarchive-descriptor`.
    export HOME="$(mktemp --directory --tmpdir fake-home.XXXXXX)"
    mkdir -p "$HOME/.cache/eldev"
    eldev doctor
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    runHook postInstall
  '';
})
