{
  description = "{{project.description}}";

  nixConfig = {
    ## https://github.com/NixOS/rfcs/blob/master/rfcs/0045-deprecate-url-syntax.md
    extra-experimental-features = ["no-url-literals"];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
    extra-trusted-substituters = ["https://cache.garnix.io"];
    ## Isolate the build.
    registries = false;
    sandbox = true;
  };

  outputs = inputs: let
    pname = "{{project.name}}";
    ename = "emacs-${pname}";
  in
    {
      overlays = {
        default = final: prev: {
          emacsPackagesFor = emacs:
            (prev.emacsPackagesFor emacs).overrideScope'
            (inputs.self.overlays.emacs final prev);
        };

        emacs = final: prev: efinal: eprev: {
          "${pname}" = inputs.self.packages.${final.system}.${ename};
        };
      };

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (inputs.flaky.lib.homeConfigurations.example
            pname
            inputs.self
            [({pkgs, ...}: {
              home.packages = [
                (pkgs.emacs.withPackages (epkgs: [
                  epkgs.${pname}
                ]))
              ];
            })])
          inputs.flake-utils.lib.defaultSystems);
    }
    // inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [(import ./nix/dependencies.nix)];
      };

      emacsPath = package:
        "${package}/share/emacs/site-lisp/elpa/${package.pname}-${package.version}";

      ## Read version in format: ;; Version: xx.yy
      readVersion = fp:
        builtins.elemAt
        (builtins.match
          ".*(;; Version: ([[:digit:]]+\.[[:digit:]]+(\.[[:digit:]]+)?)).*"
          (builtins.readFile fp))
        1;

      src = pkgs.lib.cleanSource ./.;

      format = inputs.flaky.lib.format pkgs {};

      ## We need to tell Eldev where to find its Emacs package.
      ELDEV_LOCAL = emacsPath pkgs.emacsPackages.eldev;
    in {
      packages = {
        default = inputs.self.packages.${system}.${ename};

        "${ename}" =
          inputs.bash-strict-mode.lib.checkedDrv pkgs
          (pkgs.emacsPackages.trivialBuild {
            inherit ELDEV_LOCAL pname src;

            version = readVersion ./${pname}.el;

            nativeBuildInputs = [
              (pkgs.emacsWithPackages (epkgs: [
                epkgs.buttercup
              ]))
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
      };

      devShells.default =
        inputs.flaky.lib.devShells.default pkgs inputs.self [] "";

      checks = {
        elisp-doctor =
          inputs.bash-strict-mode.lib.checkedDrv pkgs
          (pkgs.runCommand "eldev-doctor" {
              inherit ELDEV_LOCAL src;

              nativeBuildInputs = [
                pkgs.emacs
                # Emacs-lisp build tool, https://doublep.github.io/eldev/
                pkgs.emacsPackages.eldev
              ];
            } ''
              eldev doctor
              mkdir -p "$out"
            '');

        elisp-lint =
          ## TODO: Can’t currently use `inputs.bash-strict-mode.lib.checkedDrv`
          ##       because the `emacs` wrapper script checks for existence of a
          ##       variable with `-n` intead of `-v`.
          inputs.bash-strict-mode.lib.shellchecked pkgs
          (pkgs.stdenv.mkDerivation {
            inherit ELDEV_LOCAL src;

            name = "eldev-lint";

            nativeBuildInputs = [
              pkgs.emacs
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

        format = format.check inputs.self;
      };

      formatter = format.wrapper;
    });

  inputs = {
    bash-strict-mode = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:sellout/bash-strict-mode";
    };

    flake-utils.url = "github:numtide/flake-utils";

    flaky.url = "github:sellout/flaky";

    nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";
  };
}
