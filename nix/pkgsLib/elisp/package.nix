{
  ELDEV_LOCAL,
  checkedDrv,
  emacs,
  emacsPackages,
  lib,
  ...
}: pname: src: epkgs: let
  emacsWithPkgs = emacs.pkgs.withPackages (e: epkgs e ++ [e.buttercup]);

  ## Need `--external` here so that we don’t try to download any package
  ## archives (which would break the sandbox).
  eldev = args: ''
    ## TODO: Currently needed to make a temp file in
    ##      `eldev--create-internal-pseudoarchive-descriptor`.
    HOME="$(mktemp --directory --tmpdir fake-home.XXXXXX)" \
      eldev --debug --external ${args}
  '';
in
  checkedDrv (emacsPackages.trivialBuild {
    inherit ELDEV_LOCAL pname src;

    version = lib.elisp.readVersion "${src}/${pname}.el";

    nativeBuildInputs = [
      emacsWithPkgs
      # Emacs-lisp build tool, https://doublep.github.io/eldev/
      emacsPackages.eldev
    ];

    postPatch = lib.elisp.setUpLocalDependencies emacsWithPkgs.deps;

    doCheck = true;

    checkPhase = ''
      runHook preCheck
      ${eldev "test"}
      runHook postCheck
    '';

    ## FIXME: Temporarily disabled because Eldev isn’t finding the test files
    doInstallCheck = false;

    installCheckPhase = ''
      runHook preInstallCheck
      ${eldev "--packaged test"}
      runHook postInstallCheck
    '';
  })
