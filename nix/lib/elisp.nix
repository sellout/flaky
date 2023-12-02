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

  ## Ideally this could just
  ##     (setq eldev-external-package-dir "${deps}/share/emacs/site-lisp/elpa")
  ## but Eldev wants to write to that directory, even if there's nothing to
  ## download.
  setUpLocalDependencies = deps: ''
    {
      echo
      echo "(mapcar 'eldev-use-local-dependency"
      echo "        (directory-files"
      echo "         \"${deps}/share/emacs/site-lisp/elpa\""
      echo "         t"
      echo "         directory-files-no-dot-files-regexp))"
    } >> Eldev
  '';
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

    lint = pkgs: src: epkgs: let
      emacsWithPackages = pkgs.emacsWithPackages (e:
        [
          e.elisp-lint
          e.package-lint
          e.relint
        ]
        ++ epkgs e);
    in
      bash-strict-mode.lib.checkedDrv pkgs
      (pkgs.stdenv.mkDerivation {
        inherit src;

        ELDEV_LOCAL = ELDEV_LOCAL pkgs;

        name = "eldev lint";

        nativeBuildInputs = [
          emacsWithPackages
          pkgs.emacsPackages.eldev
        ];

        postPatch = setUpLocalDependencies emacsWithPackages.deps;

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

  package = pkgs: src: pname: epkgs: let
    emacsWithPackages = pkgs.emacsWithPackages epkgs;
  in
    bash-strict-mode.lib.checkedDrv pkgs
    (pkgs.emacsPackages.trivialBuild {
      inherit pname src;

      ELDEV_LOCAL = ELDEV_LOCAL pkgs;

      version = readVersion "${src}/${pname}.el";

      nativeBuildInputs = [
        emacsWithPackages
        # Emacs-lisp build tool, https://doublep.github.io/eldev/
        pkgs.emacsPackages.eldev
      ];

      postPatch = setUpLocalDependencies emacsWithPackages.deps;

      doCheck = true;

      checkPhase = ''
        runHook preCheck
        ## TODO: Currently needed to make a temp file in
        ##      `eldev--create-internal-pseudoarchive-descriptor`.
        export HOME="$PWD/fake-home"
        mkdir -p "$HOME"
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
    });
}
