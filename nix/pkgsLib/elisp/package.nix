{
  ELDEV_LOCAL,
  checkedDrv,
  emacsPackages,
  emacsWithPackages,
  lib,
  ...
}: pname: src: epkgs: let
  emacs = emacsWithPackages epkgs;
in
  checkedDrv (emacsPackages.trivialBuild {
    inherit ELDEV_LOCAL pname src;

    version = lib.elisp.readVersion "${src}/${pname}.el";

    nativeBuildInputs = [
      emacs
      # Emacs-lisp build tool, https://doublep.github.io/eldev/
      emacsPackages.eldev
    ];

    postPatch = lib.elisp.setUpLocalDependencies emacs.deps;

    doCheck = true;

    checkPhase = ''
      runHook preCheck
      ## TODO: Currently needed to make a temp file in
      ##      `eldev--create-internal-pseudoarchive-descriptor`.
      export HOME="$(mktemp --directory --tmpdir fake-home.XXXXXX)"
      ## Need `--external` here so that we don’t try to download any
      ## package archives (which would break the sandbox).
      eldev --external test
      runHook postCheck
    '';

    doInstallCheck = true;

    installCheckPhase = ''
      runHook preInstallCheck
      ## Need `--external` here so that we don’t try to download any
      ## package archives (which would break the sandbox).
      eldev --external --packaged test
      runHook postInstallCheck
    '';
  })
