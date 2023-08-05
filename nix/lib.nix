{
  bash-strict-mode,
  home-manager,
  nixpkgs,
  self,
  treefmt-nix,
}: {
  checks = {
    simple = pkgs: src: name: nativeBuildInputs: cmd:
      bash-strict-mode.lib.checkedDrv pkgs
      (pkgs.runCommand name {inherit nativeBuildInputs src;} ''
        ${cmd}
        mkdir -p "$out"
      '');

    validate-template = name: pkgs: src:
      self.lib.checks.simple
      pkgs
      src
      "nix flake init"
      [pkgs.cacert pkgs.mustache-go pkgs.nix pkgs.moreutils]
      ''
        mkdir -p "$out"
        ## TODO: Figure out why this needs `HOME` set.
        HOME="$out"
        nix --accept-flake-config --extra-experimental-features "flakes nix-command" flake \
          new "${name}-example" --template "${src}#${name}"
        cd "${name}-example"
        find . -type f -exec bash -c \
          'mustache "${src}/templates/example.yaml" "$0" | sponge "$0"' \
          {} \;
        ## Format before checking, because templating may affect
        ## formatting.
        ## TODO: Make files resilient to template formatting, so we can
        ##       remove this.
        nix --accept-flake-config \
            --extra-experimental-features "flakes nix-command" \
            fmt
        nix --accept-flake-config \
            --extra-experimental-features "flakes nix-command" \
            --print-build-logs \
            flake check
      '';
  };

  devShells.default = pkgs: self: nativeBuildInputs: shellHook:
    bash-strict-mode.lib.checkedDrv pkgs
    (pkgs.mkShell {
      inherit shellHook;

      inputsFrom =
        builtins.attrValues self.checks.${pkgs.system}
        ++ builtins.attrValues (
          if self ? packages
          then self.packages.${pkgs.system}
          else {}
        );

      nativeBuildInputs =
        [
          # Nix language server,
          # https://github.com/oxalica/nil#readme
          pkgs.nil
          # Bash language server,
          # https://github.com/bash-lsp/bash-language-server#readme
          pkgs.nodePackages.bash-language-server
        ]
        ++ nativeBuildInputs;
    });

  elisp = let
    emacsPath = package: "${package}/share/emacs/site-lisp/elpa/${package.pname}-${package.version}";

    ## We need to tell Eldev where to find its Emacs package.
    ELDEV_LOCAL = pkgs: emacsPath pkgs.emacsPackages.eldev;
  in {
    inherit ELDEV_LOCAL emacsPath;

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
      ## TODO: Can’t currently use `bash-strict-mode.lib.checkedDrv`
      ##       because the `emacs` wrapper script checks for existence of a
      ##       variable with `-n` intead of `-v`.
        bash-strict-mode.lib.shellchecked pkgs
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
              echo " '(\"${emacsPath pkgs.emacsPackages.dash}\""
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
            eldev --external lint
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

        version = self.lib.elisp.readVersion "${src}/${pname}.el";

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

    ## Read version in format: ;; Version: x.y(.z)?
    readVersion = fp:
      builtins.elemAt
      (builtins.match
        ".*(;; Version: ([[:digit:]]+\.[[:digit:]]+(\.[[:digit:]]+)?)).*"
        (builtins.readFile fp))
      1;
  };

  format = pkgs: config:
    (treefmt-nix.lib.evalModule pkgs ({
        projectRootFile = "flake.nix";
        programs = {
          ## Nix formatter
          alejandra.enable = true;
          ## Shell linter
          shellcheck.enable = true;
          ## Web/JSON/Markdown/TypeScript/YAML formatter
          prettier.enable = true;
          ## Shell formatter
          shfmt = {
            enable = true;
            ## NB: This has to be unset to allow the .editorconfig
            ##     settings to be used. See numtide/treefmt-nix#96.
            indent_size = null;
          };
        };
      }
      // config))
    .config
    .build;

  homeConfigurations.example = name: self: modules: system: {
    name = "${system}-${name}-example";
    value = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
      };

      modules =
        [
          {
            # These attributes are simply required by home-manager.
            home = {
              homeDirectory = /tmp/${name}-example;
              stateVersion = "23.05";
              username = "${name}-example-user";
            };
          }
        ]
        ++ modules;
    };
  };
}
