{
  garnix-systems,
  home-manager,
  lib,
  nixpkgs,
  project-manager,
  self,
  supportedSystems,
}: let
  garnixSystems = import garnix-systems;
in {
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

  elisp = import ./elisp.nix;

  homeConfigurations.example = self: modules: system: {
    name = "${system}-example";
    value = home-manager.lib.homeManagerConfiguration {
      pkgs =
        nixpkgs.legacyPackages.${system}.appendOverlays [self.overlays.default];

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
  projectConfigurations = let
    base = primaryModule: {modules ? [], ...} @ args:
      project-manager.lib.defaultConfiguration (
        ## `@` patterns are simply pattern matchers, they don’t construct a new
        ## value, so they don’t pick up the defaults set by `?` (see
        ## NixOS/nix#334). This is consequently a “workaround” for that behavior.
        {supportedSystems = supportedSystems;}
        // args
        // {
          modules =
            [
              {_module.args.flaky = self;}
              primaryModule
            ]
            ++ modules;
        }
      );
  in {
    default = base self.projectModules.default;
    bash = base self.projectModules.bash;
    c = base self.projectModules.c;
    dhall = base self.projectModules.dhall;
    emacs-lisp = base self.projectModules.emacs-lisp;
    haskell = base self.projectModules.haskell;
    nix = base self.projectModules.nix;
  };

  ## Converts a list of values parameterized by  a system (generally flake
  ## attributes like `sys: "packages.${sys}.foo"`) and replicates each of them
  ## for each of the systems supported by both garnix and `supportedSystems`.
  ##
  ## Type: [string] -> (string -> [a]) -> [a]
  forGarnixSystems = supportedSystems:
    lib.flip lib.concatMap (lib.intersectLists garnixSystems supportedSystems);

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
  }:
    if options ? homebrew
    then darwinConfig
    else if options ? home
    then homeConfig
    else if options ? boot
    then nixosConfig
    else projectConfig;
}
