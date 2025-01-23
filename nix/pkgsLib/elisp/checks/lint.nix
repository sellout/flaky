{
  ELDEV_LOCAL,
  checkedDrv,
  emacs,
  emacsPackages,
  lib,
  stdenv,
}: src: epkgs: let
  emacsWithPkgs = emacs.pkgs.withPackages (e:
    [
      e.elisp-lint
      e.package-lint
      e.relint
    ]
    ++ epkgs e);

  eldev = args: ''
    ## TODO: Currently needed to make a temp file in
    ##      `eldev--create-internal-pseudoarchive-descriptor`.
    HOME="$(mktemp --directory --tmpdir fake-home.XXXXXX)" \
      eldev --debug --use-emacsloadpath ${args}
  '';
in
  checkedDrv (stdenv.mkDerivation {
    inherit ELDEV_LOCAL src;

    name = "eldev lint";

    nativeBuildInputs = [
      emacsWithPkgs
      emacsPackages.eldev
    ];

    configurePhase = ''
      runHook preConfigure
      ## Build complains if this is unset.
      export EMACSNATIVELOADPATH=
      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild
      ${eldev "lint --required"}
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      runHook preInstall
    '';
  })
