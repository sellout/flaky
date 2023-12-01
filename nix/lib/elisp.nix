{bash-strict-mode}: let
  emacsPath = package: "${package}/share/emacs/site-lisp/elpa/${package.pname}-${package.version}";

  ## We need to tell Eldev where to find its Emacs package.
  ELDEV_LOCAL = pkgs: emacsPath pkgs.emacsPackages.eldev;

  ## Read version in format: ;; Version: x.y(.z)?
  readVersion = fp:
    builtins.elemAt
    (builtins.match
      ".*(;; Version: ([[:digit:]]+\.[[:digit:]]+(\.[[:digit:]]+)?)).*"
      (builtins.readFile fp))
    1;
in {
  inherit ELDEV_LOCAL emacsPath readVersion;

  checks = {
    doctor = pkgs: src:
      bash-strict-mode.lib.checkedDrv pkgs
      (pkgs.stdenv.mkDerivation {
        inherit src;

        ELDEV_LOCAL = ELDEV_LOCAL pkgs;

        name = "eldev doctor";

        nativeBuildInputs = [
          pkgs.emacs
          # Emacs-lisp build tool, https://doublep.github.io/eldev/
          pkgs.emacsPackages.eldev
        ];

        buildPhase = ''
          runHook preBuild
          ## TODO: Currently needed to make a temp file in
          ##      `eldev--create-internal-pseudoarchive-descriptor`.
          export HOME="$PWD/fake-home"
          mkdir -p "$HOME/.cache/eldev"
          eldev doctor
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p "$out"
          runHook postInstall
        '';
      });

    lint = pkgs: src: epkgs:
      bash-strict-mode.lib.checkedDrv pkgs
      (pkgs.stdenv.mkDerivation {
        inherit src;

        ELDEV_LOCAL = ELDEV_LOCAL pkgs;

        name = "eldev lint";

        nativeBuildInputs = [
          (pkgs.emacsWithPackages epkgs)
          pkgs.emacsPackages.eldev
        ];

        postPatch = ''
          {
            echo
            echo "(mapcar"
            echo " 'eldev-use-local-dependency"
            echo " '(\"${emacsPath pkgs.emacsPackages.compat}\""
            echo "   \"${emacsPath pkgs.emacsPackages.dash}\""
            echo "   \"${emacsPath pkgs.emacsPackages.elisp-lint}\""
            echo "   \"${emacsPath pkgs.emacsPackages.package-lint}\""
            echo "   \"${emacsPath pkgs.emacsPackages.relint}\""
            echo "   \"${emacsPath pkgs.emacsPackages.xr}\"))"
          } >> Eldev
        '';

        buildPhase = ''
          runHook preBuild
          ## TODO: Currently needed to make a temp file in
          ##      `eldev--create-internal-pseudoarchive-descriptor`.
          export HOME="$PWD/fake-home"
          mkdir -p "$HOME"

          ## Need `--external` here so that we don’t try to download any
          ## package archives (which would break the sandbox).
          ## TODO: I'm not sure why this needs `EMACSNATIVELOADPATH`, but it
          ##       does.
          EMACSNATIVELOADPATH= eldev --external lint --required
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p "$out"
          runHook preInstall
        '';
      });
  };

  overlays.default = emacsOverlay: final: prev: {
    emacsPackagesFor = emacs:
      (prev.emacsPackagesFor emacs).overrideScope'
      (emacsOverlay final prev);
  };

  package = pkgs: src: pname: epkgs:
    bash-strict-mode.lib.checkedDrv pkgs
    (pkgs.emacsPackages.trivialBuild {
      inherit pname src;

      ELDEV_LOCAL = ELDEV_LOCAL pkgs;

      version = readVersion "${src}/${pname}.el";

      nativeBuildInputs = [
        (pkgs.emacsWithPackages (e: [e.buttercup] ++ epkgs e))
        # Emacs-lisp build tool, https://doublep.github.io/eldev/
        pkgs.emacsPackages.eldev
      ];

      postPatch = ''
        {
          echo
          echo "(mapcar"
          echo " 'eldev-use-local-dependency"
          echo " '(\"${emacsPath pkgs.emacsPackages.buttercup}\"))"
        } >> Eldev
      '';

      doCheck = true;

      checkPhase = ''
        runHook preCheck
        ## TODO: Currently needed to make a temp file in
        ##      `eldev--create-internal-pseudoarchive-descriptor`.
        export HOME="$PWD/fake-home"
        mkdir -p "$HOME"
        eldev --external test
        runHook postCheck
      '';

      doInstallCheck = true;

      installCheckPhase = ''
        runHook preInstallCheck
        eldev --external --packaged test
        runHook postInstallCheck
      '';
    });
}
