{
  bash-strict-mode,
  home-manager,
  nixpkgs,
  project-manager,
  self,
}: {
  checks = let
    simple = pkgs: src: name: nativeBuildInputs: cmd:
      bash-strict-mode.lib.checkedDrv pkgs
      (pkgs.runCommand name {inherit nativeBuildInputs src;} ''
        ${cmd}
        mkdir -p "$out"
      '');
  in {
    inherit simple;

    validate-template = name: pkgs: src:
      simple
      pkgs
      src
      "validate ${name}"
      [pkgs.cacert pkgs.mustache-go pkgs.nix pkgs.moreutils pkgs.project-manager]
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
        ## Speed up the check by priming the lockfile.
        cp "$src/flake.lock" ./
        chmod +w ./flake.lock
        project-manager switch --accept-flake-config
        ## Format the README before checking, because templating may affect
        ## formatting.
        nix --accept-flake-config \
            --extra-experimental-features "flakes nix-command" \
            fmt README.md
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

  elisp = import ./lib/elisp.nix {inherit bash-strict-mode;};

  homeConfigurations.example = name: self: modules: system: {
    name = "${name}-example [${system}]";
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

  ## Adds `flaky` as an additional module argument.
  projectConfigurations.default = {modules ? [], ...} @ args:
    project-manager.lib.defaultConfiguration (args // {
      modules = modules ++ [
        { _module.args.flaky = self;
        }
        self.projectModules.default
      ];
    });

  garnixChecks = let
    ## The systems supported by garnix.
    ##
    ## TODO: Ideally we would intersect this with the set of systems used in the
    ##       flake.
    garnixSystems = ["aarch64-darwin" "aarch64-linux" "x86_64-linux"];
  in jobNameFn: map jobNameFn garnixSystems;
}
