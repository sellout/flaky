{
  description = "Templates for dev environments.";

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

  outputs = inputs:
    {
      overlays = {
        elisp-dependencies = import ./nix/elisp-dependencies.nix;
      };

      lib = {
        checks = {
          elisp = let
            emacsPath = inputs.self.lib.elisp.emacsPath;
          in {
            doctor = pkgs: src:
              inputs.bash-strict-mode.lib.checkedDrv pkgs
              (pkgs.runCommand "eldev doctor" {
                  inherit src;
                  inherit (inputs.self.lib.elisp) ELDEV_LOCAL;

                  nativeBuildInputs = [
                    pkgs.emacs
                    # Emacs-lisp build tool, https://doublep.github.io/eldev/
                    pkgs.emacsPackages.eldev
                  ];
                } ''
                  eldev doctor
                  mkdir -p "$out"
                '');

            lint = pkgs: src:
            ## TODO: Can’t currently use `inputs.bash-strict-mode.lib.checkedDrv`
            ##       because the `emacs` wrapper script checks for existence of a
            ##       variable with `-n` intead of `-v`.
              inputs.bash-strict-mode.lib.shellchecked pkgs
              (pkgs.stdenv.mkDerivation {
                inherit src;
                inherit (inputs.self.lib.elisp) ELDEV_LOCAL;

                name = "eldev lint";

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
          };

          simple = pkgs: src: name: nativeBuildInputs: cmd:
            inputs.bash-strict-mode.lib.checkedDrv pkgs
            (pkgs.runCommand name {inherit nativeBuildInputs src;} ''
              ${cmd}
              mkdir -p "$out"
            '');

          validate-template = name: pkgs: src:
            inputs.self.lib.checks.simple
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
          inputs.bash-strict-mode.lib.checkedDrv pkgs
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

        elisp = {
          emacsPath = package: "${package}/share/emacs/site-lisp/elpa/${package.pname}-${package.version}";
          ## We need to tell Eldev where to find its Emacs package.
          ELDEV_LOCAL = pkgs:
            inputs.self.lib.elisp.emacsPath pkgs.emacsPackages.eldev;

          ## Read version in format: ;; Version: x.y(.z)?
          readVersion = fp:
            builtins.elemAt
            (builtins.match
              ".*(;; Version: ([[:digit:]]+\.[[:digit:]]+(\.[[:digit:]]+)?)).*"
              (builtins.readFile fp))
            1;
        };

        format = pkgs: config:
          (inputs.treefmt-nix.lib.evalModule pkgs ({
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
          value = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = import inputs.nixpkgs {
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

        overlays.elisp.default = emacsOverlay: final: prev: {
          emacsPackagesFor = emacs:
            (prev.emacsPackagesFor emacs).overrideScope'
            (emacsOverlay final prev);
        };

        packages.elisp = pkgs: src: pname:
          inputs.bash-strict-mode.lib.checkedDrv pkgs
          (pkgs.emacsPackages.trivialBuild {
            inherit pname src;
            inherit (inputs.self.lib.elisp) ELDEV_LOCAL;

            version = inputs.self.lib.elisp.readVersion ./${pname}.el;

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
                echo " '(\"${inputs.self.lib.elisp.emacsPath pkgs.emacsPackages.buttercup}\"))"
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

      templates = let
        welcomeText = ''
          See https://github.com/sellout/flaky/tree/main/README.md#templates for
          how to complete the setup of this project.
        '';
      in {
        default = inputs.self.templates.nix;
        bash = {
          inherit welcomeText;
          description = "Bash project template";
          path = ./templates/bash;
        };
        c = {
          inherit welcomeText;
          description = "C project template";
          path = ./templates/c;
        };
        emacs-lisp = {
          inherit welcomeText;
          description = "Emacs-lisp project template";
          path = ./templates/emacs-lisp;
        };
        haskell = {
          inherit welcomeText;
          description = "Haskell project template";
          path = ./templates/haskell;
        };
        nix = {
          inherit welcomeText;
          description = ''
            Nix project template (other templates are derived from this one)
          '';
          path = ./templates/nix;
        };
      };
    }
    // inputs.flake-utils.lib.eachSystem inputs.flake-utils.lib.defaultSystems
    (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [inputs.bash-strict-mode.overlays.default];
      };

      format = inputs.self.lib.format pkgs {
        ## NB: This is normally "flake.nix", but since this repo contains
        ##     sub-flakes, we use the .git/config because it is unique.
        projectRootFile = ".git/config";
        ## Each template has its own formatter that is run during checks, so we
        ## don’t check them here. The `*/*` is needed so that we don’t miss
        ## formatting anything in the templates directory that is not part of a
        ## specific template.
        settings.global.excludes = ["templates/*/*"];
      };
    in {
      ## These shells are quick-and-dirty development environments for various
      ## programming languages. They’re meant to be used in projects that don’t
      ## have any Nix support provided. There should be a
      ## `config.home.sessionAlias` defined in ./nix/home.nix for each of them,
      ## but adding a .envrc to the project directory (assuming the project
      ## doesn’t provide one) is a more permanent solution (but I need to figure
      ## out exactly what to put in the .envrc).
      ##
      ## TODO: Most (all?) of these parallel the templates defined below. We
      ##      _might_ want to have each of these extend the relevant template’s
      ##      `devShells.default`. (Is that possible?) However, these should
      ##       still exist, because the templates build our _preferred_
      ##       environment, but these often provide multiple duplicate tools to
      ##       work within the context of any project in the ecosystem.
      ## TODO: These generally leave the system open to infection (e.g., putting
      ##       specific Hackage packages in ~/.cabal/), but it would be great if
      ##       they could re-locate things to the Nix store or at least local to
      ##       the project.
      devShells = let
        extendDevShell = shell: nativeBuildInputs:
          inputs.self.devShells.${system}.${shell}.overrideAttrs (old: {
            nativeBuildInputs = old.nativeBuildInputs ++ nativeBuildInputs;
          });
      in {
        default = inputs.self.lib.devShells.default pkgs inputs.self [] "";
        ## This provides tooling that could be useful in _any_ Nix project, if
        ## there’s not a specific one.
        nix = inputs.bash-strict-mode.lib.checkedDrv pkgs (pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.bash-strict-mode
            pkgs.nil
            pkgs.nodePackages.bash-language-server
            pkgs.shellcheck
            pkgs.shfmt
          ];
        });
        bash = extendDevShell "nix" [
          pkgs.bash
          pkgs.bash-strict-mode
          pkgs.nodePackages.bash-language-server
          pkgs.shellcheck
          pkgs.shfmt
        ];
        c = extendDevShell "nix" [
          pkgs.clang
          pkgs.cmake
          pkgs.gcc
          pkgs.gnumake
        ];
        emacs-lisp = extendDevShell "nix" [
          pkgs.cask
          pkgs.emacs
          pkgs.emacsPackages.eldev
        ];
        haskell = extendDevShell "nix" [
          pkgs.cabal-install
          # We don’t need `ghcWithPackages` here because the build tool should
          # handle the dependencies. Stack bundles GHC, but Cabal needs a
          # version installed.
          pkgs.ghc
          pkgs.haskell-language-server
          pkgs.hpack
          pkgs.ormolu
          pkgs.stack
        ];
        rust =
          extendDevShell "nix"
          (inputs.nixpkgs.lib.optional
            (system == inputs.flake-utils.lib.system.aarch64-darwin)
            pkgs.libiconv
            ++ [
              pkgs.cargo
              pkgs.rustc
            ]);
        scala = extendDevShell "nix" [pkgs.sbt];
      };

      checks = let
        src = pkgs.lib.cleanSource ./.;
      in
        {
          format = format.check inputs.self;
        }
        // builtins.listToAttrs (map (name: {
            name = "${name}-template-validity";
            value = inputs.self.lib.checks.validate-template name pkgs src;
          })
          ## TODO: These two templates require renaming files, so they don’t
          ##       work with this check yet.
          (pkgs.lib.remove "emacs-lisp"
            (pkgs.lib.remove "haskell"
              (builtins.attrNames inputs.self.templates))));

      formatter = format.wrapper;
    });

  inputs = {
    bash-strict-mode = {
      inputs = {
        flaky.follows = "";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/bash-strict-mode";
    };

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager/release-23.05";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";

    ## Nix unit-testing
    nixt = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/nixt";
    };

    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };
  };
}
