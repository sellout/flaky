{
  description = "Templates for dev environments";

  nixConfig = {
    ## https://github.com/NixOS/rfcs/blob/master/rfcs/0045-deprecate-url-syntax.md
    extra-experimental-features = ["no-url-literals"];
    extra-substituters = ["https://cache.garnix.io"];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
    ## Isolate the build.
    registries = false;
    ## Disabled so that checks that require Internet access can run.
    sandbox = false;
  };

  outputs = inputs:
    {
      schemas = {
        inherit (inputs.project-manager.schemas)
          overlays
          # lib
          templates
          projectModules
          projectConfigurations
          devShells
          apps
          packages
          checks
          formatter;
      };

      overlays = {
        elisp-dependencies = import ./nix/elisp-dependencies.nix;
      };

      lib = import ./nix/lib.nix {
        inherit (inputs)
          bash-strict-mode
          home-manager
          nixpkgs
          project-manager
          self;
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
        dhall = {
          inherit welcomeText;
          description = "Dhall project template";
          path = ./templates/dhall;
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

      projectModules = {
        ## The settings shared across my projects.
        default = ./base/.config/project;
        hacktoberfest = ./base/.config/project/hacktoberfest.nix;
      };
    }
    // inputs.flake-utils.lib.eachSystem inputs.flake-utils.lib.defaultSystems
    (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          inputs.bash-strict-mode.overlays.default
          inputs.project-manager.overlays.default
        ];
      };
    in {
      projectConfigurations =
        inputs.self.lib.projectConfigurations.default {
          inherit pkgs;
          inherit (inputs) self;
        };

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
      in inputs.self.projectConfigurations.${system}.devShells // {
        # inputs.self.lib.devShells.default pkgs inputs.self [] "";
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
        dhall = extendDevShell "nix" [
          pkgs.dhall
          pkgs.dhall-docs
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

      apps.sync-template = {
        type = "app";
        program = "${inputs.self.packages.${system}.management-scripts}/bin/sync-template";
      };

      packages.management-scripts =
        inputs.bash-strict-mode.lib.checkedDrv pkgs
        (pkgs.stdenv.mkDerivation {
          pname = "flaky-management-scripts";
          version = "0.1.0";
          src = ./scripts;
          meta = {
            description = "Scripts for managing poly-repo projects";
            longDescription = ''
              Making it simpler to manage poly-repo projects (and
              projectiverses).
            '';
          };

          nativeBuildInputs = [pkgs.bats pkgs.makeWrapper];

          patchPhase = ''
            runHook prePatch
            ( # Remove +u (and subshell) once NixOS/nixpkgs#207203 is merged
              set +u
              patchShebangs .
            )
            runHook postPatch
          '';

          # doCheck = true;

          # checkPhase = ''
          #   bats --print-output-on-failure ./test/all-tests.bats
          # '';

          ## This isn’t executable, but putting it in `bin/` makes it possible
          ## for `source` to find it without a path.
          installPhase = ''
            runHook preInstall
            mkdir -p "$out/bin/"
            cp ./* "$out/bin/"
            runHook postInstall
          '';

          postFixup = ''
            ( # Remove +u (and subshell) once NixOS/nixpkgs#247410 is fixed
              set +u
              wrapProgram $out/bin/sync-template \
                --prefix PATH : ${pkgs.lib.makeBinPath [
              pkgs.moreutils
              pkgs.mustache-go
              pkgs.yq
            ]}
            )
          '';

          # doInstallCheck = true;
        });

      checks = let
        src = pkgs.lib.cleanSource ./.;
      in
        inputs.self.projectConfigurations.${system}.checks
        // builtins.listToAttrs (map (name: {
            name = "${name}-template-validity";
            value = inputs.self.lib.checks.validate-template name pkgs src;
          })
          ## TODO: These two templates require renaming files, so they don’t
          ##       work with this check yet.
          (pkgs.lib.remove "emacs-lisp"
            (pkgs.lib.remove "haskell"
              (builtins.attrNames inputs.self.templates))));

      formatter = inputs.self.projectConfigurations.${system}.formatter;
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

    project-manager = {
      inputs = {
        bash-strict-mode.follows = "bash-strict-mode";
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/project-manager";
    };
  };
}
