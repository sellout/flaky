{
  description = "Shared configuration for dev environments";

  nixConfig = {
    ## https://github.com/NixOS/rfcs/blob/master/rfcs/0045-deprecate-url-syntax.md
    extra-experimental-features = ["no-url-literals"];
    extra-substituters = ["https://cache.garnix.io"];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
    ## Isolate the build.
    sandbox = "relaxed";
    use-registries = false;
  };

  outputs = {
    bash-strict-mode,
    flake-utils,
    garnix-systems,
    home-manager,
    nixpkgs,
    nixpkgs-unstable,
    project-manager,
    self,
    systems,
  }: let
    sys = flake-utils.lib.system;

    supportedSystems = import systems;
  in
    {
      ## These are also consumed by downstream projects, so it may include more
      ## than is referenced in this flake.
      schemas = project-manager.schemas;

      overlays = {
        default = final: prev: {
          flaky-management-scripts =
            self.packages.${final.system}.management-scripts;
        };

        elisp-dependencies = import ./nix/elisp-dependencies.nix;

        dependencies = final: prev: {
          haskellPackages =
            prev.haskellPackages.extend
            (self.overlays.haskellDependencies final prev);

          ## NB: The `treefmt2` in Nixpkgs 24.05 fails when multiple formatters
          ##     apply to the same file (which is a problem when we have both a
          ##     formatter and linter(s)).
          treefmt2 = nixpkgs-unstable.legacyPackages.${final.system}.treefmt2;
        };

        haskellDependencies = import ./nix/haskell-dependencies.nix;
      };

      lib = import ./nix/lib.nix {
        inherit
          bash-strict-mode
          flake-utils
          garnix-systems
          home-manager
          nixpkgs
          project-manager
          self
          supportedSystems
          ;
      };

      projectModules = {
        ## The settings shared across my projects.
        default = ./base/.config/project;
        bash = ./base/.config/project/bash;
        c = ./base/.config/project/c;
        dhall = ./base/.config/project/dhall;
        emacs-lisp = ./base/.config/project/emacs-lisp;
        hacktoberfest = ./base/.config/project/hacktoberfest.nix;
        haskell = ./base/.config/project/haskell;
        nix = ./base/.config/project/nix;
      };
    }
    // flake-utils.lib.eachSystem supportedSystems
    (system: let
      pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
        bash-strict-mode.overlays.default
        project-manager.overlays.default
        self.overlays.dependencies
      ];
    in {
      devShells =
        self.projectConfigurations.${system}.devShells
        // {default = self.lib.devShells.default system self [] "";};

      projectConfigurations = self.lib.projectConfigurations.nix {
        inherit pkgs self;
        modules = [self.projectModules.bash];
      };

      checks = self.projectConfigurations.${system}.checks;
      formatter = self.projectConfigurations.${system}.formatter;
    });

  inputs = {
    bash-strict-mode = {
      inputs.flaky.follows = "";
      url = "github:sellout/bash-strict-mode";
    };

    flake-utils = {
      inputs.systems.follows = "systems";
      url = "github:numtide/flake-utils";
    };

    garnix-systems.url = "github:garnix-io/nix-systems";

    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager/release-24.05";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";

    nixpkgs-unstable.follows = "project-manager/nixpkgs-unstable";

    project-manager = {
      inputs.flaky.follows = "";
      url = "github:sellout/project-manager";
    };

    ## See https://github.com/nix-systems/nix-systems#readme for an explanation
    ## of this input.
    systems.url = "github:sellout/nix-systems";
  };
}
