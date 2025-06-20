{
  ELDEV_LOCAL,
  checkedDrv,
  emacs,
  emacsPackages,
  lib,
  tree,
  stdenv,
  writeText,
}: pname: src: epkgs: let
  emacsWithPkgs = emacs.pkgs.withPackages epkgs;

  eldev = args: ''
    ## TODO: Currently needed to make a temp file in
    ##      `eldev--create-internal-pseudoarchive-descriptor`.
    HOME="$(mktemp --directory --tmpdir fake-home.XXXXXX)" \
      eldev --debug --use-emacsloadpath ${lib.escapeShellArgs args}
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

    setupHook = writeText "setup-hook.sh" ''
      source ${./emacs-funcs.bash}

      if [[ ! -v emacsHookDone ]]; then
        emacsHookDone=1

        # If this is for a wrapper derivation, emacs and the dependencies are
        # all run-time dependencies. If this is for precompiling packages into
        # bytecode, emacs is a compile-time dependency of the package.
        addEnvHooks "$hostOffset" addEmacsVars
        addEnvHooks "$targetOffset" addEmacsVars
      fi
    '';

    configurePhase = ''
      runHook preConfigure
      ## Build complains if these are unset.
      export EMACSLOADPATH=
      export EMACSNATIVELOADPATH=
      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild
      EMACSLOADPATH="$PWD:$EMACSLOADPATH" \
        ${eldev ["build" "--warnings-as-errors"]}
      ${eldev ["package"]}
      runHook postBuild
    '';

    doCheck = true;

    checkPhase = ''
      runHook preCheck
      EMACSLOADPATH="$PWD:$EMACSLOADPATH" \
        ${eldev ["test"]}
      runHook postCheck
    '';

    installPhase = let
      elpaDir = "$out/share/emacs/site-lisp/elpa";
    in ''
      runHook preInstall
      ${eldev ["package"]}
      mkdir -p "${elpaDir}"
      tar -x --file dist/*.tar --directory "${elpaDir}"
      ## There should be only one directory in ${elpaDir}, but rather than
      ## having to know what it is, we just loop over all of them.
      find "${elpaDir}" -type d -mindepth 1 -maxdepth 1 -exec \
        cp *-autoloads.el {} \;
      runHook postInstall
    '';

    doInstallCheck = true;

    installCheckPhase = ''
      runHook preInstallCheck
      ${eldev ["--packaged" "test"]}
      runHook postInstallCheck
    '';
  })
