{
  bash-strict-mode,
  home-manager,
  nixpkgs,
  treefmt-nix,
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

  elisp = import ./lib/elisp.nix {inherit bash-strict-mode;};

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
