{
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

  localPkgsLib = pkgs: import ../../nix/pkgsLib {inherit pkgs self;};

  ## Project modules that are meant to be used as top-level configurations.
  configModules = {
    default = ../../base/.config/project;
    bash = ../../base/.config/project/bash;
    c = ../../base/.config/project/c;
    dhall = ../../base/.config/project/dhall;
    emacs-lisp = ../../base/.config/project/emacs-lisp;
    haskell = ../../base/.config/project/haskell;
    nix = ../../base/.config/project/nix;
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

      elisp-dependencies = import ../../nix/elisp-dependencies.nix;

      dependencies = final: prev: {
        haskellPackages =
          prev.haskellPackages.extend
          (self.overlays.haskellDependencies final prev);

        ## TODO: Remove this once NixOS/nixpkgs#488689 is fixed.
        inetutils = let
          orig = prev.inetutils;
        in
          if final.hostPlatform.isDarwin
          then
            orig.overrideAttrs (old: let
              version = "2.6";
            in {
              inherit version;
              src = final.fetchurl {
                url = "mirror://gnu/${old.pname}/${old.pname}-${version}.tar.xz";
                hash = "sha256-aL7b/q9z99hr4qfZm8+9QJPYKfUncIk5Ga4XTAsjV8o=";
              };
            })
          else orig;
      };

      haskellDependencies = import ../../nix/haskell-dependencies.nix;
    };

    lib = import ../../nix/lib {
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
        hacktoberfest = ../../base/.config/project/hacktoberfest.nix;
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
  })
