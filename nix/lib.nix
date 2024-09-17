{
  bash-strict-mode,
  flake-utils,
  garnix-systems,
  home-manager,
  nixpkgs,
  project-manager,
  self,
  supportedSystems,
}: let
  garnixSystems = import garnix-systems;

  ## A wrapper around `pkgs.runCommand` that uses `bash-strict-mode`.
  runCommand = pkgs: name: attrs: cmd:
    bash-strict-mode.lib.checkedDrv pkgs (pkgs.runCommand name attrs cmd);

  ## A command where we don’t preserve any output can be more lax than most
  ## derivations. By turning it into a fixed-output derivation based on the
  ## command, we can weaken some of the sandbox constraints.
  runEmptyCommand = pkgs: name: attrs: command: let
    outputHashAlgo = "sha256";
    ## Runs a command and returns its output as a string.
    exec = nativeBuildInputs: cmd:
      builtins.readFile
      (builtins.toString (runCommand pkgs "exe" {inherit nativeBuildInputs;} "{ ${cmd} } > $out"));
    hashInput = str:
      runCommand pkgs "emptyCommand-hash-input" {} ''
        ## Base64-encode the command to avoid having any path references in the
        ## output.
        echo ${pkgs.lib.escapeShellArg str} | base64 > $out
      '';
    getHash = str:
      nixpkgs.lib.removeSuffix "\n" (exec [pkgs.nix] ''
        nix-hash --type ${outputHashAlgo} --base64 ${hashInput str}
      '');
  in
    runCommand pkgs name (attrs
      // {
        inherit outputHashAlgo;
        outputHash = getHash command;
        outputHashMode = "recursive";
      }) ''
      ${command}
      cp ${hashInput command} "$out"
    '';
in {
  inherit runCommand runEmptyCommand;

  checks = let
    simple = pkgs: src: name: nativeBuildInputs:
      runEmptyCommand pkgs name {inherit nativeBuildInputs src;};
  in {
    inherit simple;

    validate-template = name: pkgs:
      (simple
        pkgs
        self
        "validate ${name}"
        [
          pkgs.cacert
          pkgs.git
          pkgs.moreutils
          pkgs.mustache-go
          pkgs.nix
          pkgs.project-manager
          pkgs.rename
        ]
        ''
          export HOME="$(mktemp --directory --tmpdir fake-home.XXXXXX)"
          mkdir -p "$HOME/.local/state/nix/profiles"

          export NIX_CONFIG=$(cat <<'CONFIG'
          accept-flake-config = true
          extra-experimental-features = flakes nix-command
          CONFIG
          )

          nix flake new "${name}-example" --template "$src#${name}"
          cd "${name}-example"
          find . -iname "*{{project.name}}*" -depth \
            -execdir rename 's/{{project.name}}/template-example/g' {} +
          find . -type f -exec bash -c \
            'mustache "${self}/templates/example.yaml" "$0" | sponge "$0"' \
            {} \;
          ## Reference _this_ version of flaky, rather than a published one.
          sed -i -e 's#github:sellout/flaky#${self}#g' ./flake.nix
          git init
          git add --all
          project-manager switch
          ## Format the README before checking, because templating may affect
          ## formatting.
          nix fmt README.md
          nix --print-build-logs flake check
        '')
      .overrideAttrs (old: {__noChroot = true;});
  };

  ## TODO: Remove this once bash-strict-mode and Project Manager have migrated
  ##       to use nix-systems.
  defaultSystems = supportedSystems;

  devShells.default = system: self: nativeBuildInputs: shellHook:
    self.projectConfigurations.${system}.devShells.project-manager.overrideAttrs
    (old: {
      inputsFrom =
        old.inputsFrom
        or []
        ++ builtins.attrValues
        ## FIXME: See sellout/project-manager#61
        (removeAttrs
          self.projectConfigurations.${system}.sandboxedChecks or {}
          ["formatter"])
        ++ builtins.attrValues self.packages.${system} or {};

      nativeBuildInputs = old.nativeBuildInputs ++ nativeBuildInputs;

      shellHook = old.shellHook + shellHook;
    });

  elisp = import ./lib/elisp.nix {inherit bash-strict-mode;};

  homeConfigurations.example = self: modules: system: {
    name = "${system}-example";
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
              homeDirectory = /tmp/example;
              stateVersion = "24.05";
              username = "example-user";
            };
          }
        ]
        ++ modules;
    };
  };

  ## Adds `flaky` as an additional module argument.
  projectConfigurations.default = {modules ? [], ...} @ args:
    project-manager.lib.defaultConfiguration (
      ## `@` patterns are simply pattern matchers, they don’t construct a new
      ## value, so they don’t pick up the defaults set by `?` (see
      ## NixOS/nix#334). This is consequently a “workaround” for that behavior.
      {supportedSystems = supportedSystems;}
      // args
      // {
        modules =
          modules
          ++ [
            {_module.args.flaky = self;}
            self.projectModules.default
          ];
      }
    );

  ## Converts a list of values parameterized by  a system (generally flake
  ## attributes like `sys: "packages.${sys}.foo"`) and replicates each of them
  ## for each of the systems supported by both garnix and `supportedSystems`.
  ##
  ## Type: [string] -> (string -> [a]) -> [a]
  forGarnixSystems = supportedSystems:
    nixpkgs.lib.flip
    nixpkgs.lib.concatMap
    (nixpkgs.lib.intersectLists garnixSystems supportedSystems);

  ## Accepts separate configurations for nix-darwin, Home Manager, NixOS, and
  ## Project Manager, returning the correct one for whichever configuration is
  ## being built (guessing based on the attributes defined by `options`).
  ##
  ## This is useful for writing modules that work across multiple types of
  ## configuration.
  multiConfig = options: {
    darwinConfig ? {},
    homeConfig ? {},
    nixosConfig ? {},
    projectConfig ? {},
  }: {
    config =
      if options ? homebrew
      then darwinConfig
      else if options ? home
      then homeConfig
      else if options ? boot
      then nixosConfig
      else projectConfig;
  };
}
