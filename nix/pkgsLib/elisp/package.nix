{
  ELDEV_LOCAL,
  checkedDrv,
  emacs,
  emacsPackages,
  lib,
  stdenv,
}: pname: src: epkgs: let
  emacsWithPkgs = emacs.pkgs.withPackages epkgs;

  eldev = args: ''
    ## TODO: Currently needed to make a temp file in
    ##      `eldev--create-internal-pseudoarchive-descriptor`.
    HOME="$(mktemp --directory --tmpdir fake-home.XXXXXX)" \
      eldev --debug --use-emacsloadpath ${args}
  '';
in
  checkedDrv (stdenv.mkDerivation {
    inherit ELDEV_LOCAL pname src;

    version = lib.elisp.readVersion "${src}/${pname}.el";

    nativeBuildInputs = [
      emacsWithPkgs
      # Emacs-lisp build tool, https://doublep.github.io/eldev/
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
      EMACSLOADPATH="$PWD:$EMACSLOADPATH" \
        ${eldev "build --warnings-as-errors"}
      ${eldev "package"}
      runHook postBuild
    '';

    doCheck = true;

    checkPhase = ''
      runHook preCheck
      EMACSLOADPATH="$PWD:$EMACSLOADPATH" \
        ${eldev "test"}
      runHook postCheck
    '';

    installPhase = ''
      runHook preInstall
      ${eldev "package"}
      mkdir -p "$out/share/emacs/site-lisp/elpa"
      tar -x --file dist/*.tar --directory "$out/share/emacs/site-lisp/elpa"
      runHook postInstall
    '';

    doInstallCheck = true;

    installCheckPhase = ''
      runHook preInstallCheck
      ${eldev "--packaged test"}
      runHook postInstallCheck
    '';
  })
