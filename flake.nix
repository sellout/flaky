{
  description = "Shared configuration for dev environments";

  nixConfig = {
    ## NB: This is a consequence of using `self.pkgsLib.runEmptyCommand`, which
    ##     allows us to sandbox derivations that otherwise can’t be.
    allow-import-from-derivation = true;
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
    supportedSystems = import systems;

    localPkgsLib = pkgs: import ./nix/pkgsLib {inherit pkgs self;};

    ## Project modules that are meant to be used as top-level configurations.
    configModules = {
      default = ./base/.config/project;
      bash = ./base/.config/project/bash;
      c = ./base/.config/project/c;
      dhall = ./base/.config/project/dhall;
      emacs-lisp = ./base/.config/project/emacs-lisp;
      haskell = ./base/.config/project/haskell;
      nix = ./base/.config/project/nix;
    };
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
        configModules = nixpkgs.lib.attrNames configModules;
      };

      ## The settings shared across my projects.
      projectModules =
        configModules
        // {
          hacktoberfest = ./base/.config/project/hacktoberfest.nix;
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

      checks = let
        projectModule = name:
          (self.lib.projectConfigurations.${name} {
            inherit pkgs;
            ## TODO: Modules here sholudn’t depend on the downstream `lib`, but
            ##       should take these as options.
            self =
              self
              // {
                lib = {
                  nixifyGhcVersion = version:
                    "ghc" + nixpkgs.lib.replaceStrings ["."] [""] version;
                  nonNixTestedGhcVersions = ["9.10.1"];
                  testedGhcVersions = _: ["9.10.1"];
                };
              };
            ## Options that needs to be defined by the downstream project.
            modules = [
              (
                if name == "haskell"
                then {
                  services.haskell-ci = {
                    cabalPackages.example-package = "core";
                    defaultGhcVersion = "9.10.1";
                    ghcVersions = ["9.10.1"];
                    latestGhcVersion = "9.10.1";
                  };
                }
                else {}
              )
            ];
          }).packages.activation;
      in
        self.projectConfigurations.${system}.checks
        // nixpkgs.lib.mapAttrs' (name: _:
          nixpkgs.lib.nameValuePair (name + "ProjectModule")
          (projectModule name))
        configModules;
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
      url = "github:nix-community/home-manager/release-25.05";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";

    project-manager = {
      inputs.flaky.follows = "";
      url = "github:sellout/project-manager";
    };

    ## See https://github.com/nix-systems/nix-systems#readme for an explanation
    ## of this input.
    systems.url = "github:sellout/nix-systems";
  };
}
