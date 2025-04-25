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
    project-manager,
    self,
    systems,
  }: let
    sys = flake-utils.lib.system;

    supportedSystems = import systems;

    localPkgsLib = pkgs: import ./nix/pkgsLib {inherit pkgs self;};
  in
    {
      ## These are also consumed by downstream projects, so it may include more
      ## than is referenced in this flake.
      schemas = project-manager.schemas;

      overlays = {
        default = nixpkgs.lib.composeManyExtensions [
          bash-strict-mode.overlays.local
          project-manager.overlays.local
          self.overlays.dependencies
          self.overlays.local
        ];

        local = final: prev:
          {lib = prev.lib // self.lib;}
          // localPkgsLib final;

        elisp-dependencies = import ./nix/elisp-dependencies.nix;

        dependencies = final: prev: {
          haskellPackages =
            prev.haskellPackages.extend
            (self.overlays.haskellDependencies final prev);
          nodejs = prev.nodejs.overrideAttrs (old: {
            ## Various tests fail in various cases. One failed on i686-linux at
            ## some point, and there are more tests failing on macOS 15.4, until
            ## https://github.com/NixOS/nixpkgs/commit/bb11d476f50aa93f4129bbdc58cb004bbc601971
            ## hits a release branch.
            doCheck = false;
          });
        };

        haskellDependencies = import ./nix/haskell-dependencies.nix;
      };

      lib = import ./nix/lib {
        inherit
          garnix-systems
          home-manager
          nixpkgs
          project-manager
          self
          supportedSystems
          ;
        inherit (nixpkgs) lib;
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
      pkgsLib = localPkgsLib pkgs;

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
      url = "github:nix-community/home-manager/release-24.11";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/release-24.11";

    project-manager = {
      inputs.flaky.follows = "";
      url = "github:sellout/project-manager";
    };

    ## See https://github.com/nix-systems/nix-systems#readme for an explanation
    ## of this input.
    systems.url = "github:sellout/nix-systems";
  };
}
