{
  description = "{{project.summary}}";

  nixConfig = {
    ## https://github.com/NixOS/rfcs/blob/master/rfcs/0045-deprecate-url-syntax.md
    extra-experimental-features = ["no-url-literals"];
    extra-substituters = ["https://cache.garnix.io"];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
    ## Isolate the build.
    registries = false;
    sandbox = "relaxed";
  };

  ### This is a complicated flake. Here’s the rundown:
  ###
  ### overlays.default – includes all of the packages from cabal.project
  ### packages = {
  ###   default = points to `packages.${defaultGhcVersion}`
  ###   <ghcVersion>-<cabal-package> = an individual package compiled for one
  ###                                  GHC version
  ###   <ghcVersion>-all = all of the packages in cabal.project compiled for one
  ###                      GHC version
  ### };
  ### devShells = {
  ###   default = points to `devShells.${defaultGhcVersion}`
  ###   <ghcVersion> = a shell providing all of the dependencies for all
  ###                  packages in cabal.project compiled for one GHC version
  ### };
  ### checks.format = verify that code matches Ormolu expectations
  outputs = {
    bash-strict-mode,
    concat,
    flake-utils,
    flaky,
    nixpkgs,
    self,
  }: let
    pname = "{{project.name}}";

    supportedGhcVersions = [
      # "ghc884" # dependency compiler-rt-libc is broken in nixpkgs 23.05 & 23.11
      "ghc8107"
      "ghc902"
      "ghc928"
      "ghc945"
      "ghc961"
      # "ghcHEAD" # doctest doesn’t work on current HEAD
    ];

    supportedSystems = flake-utils.lib.defaultSystems;

    cabalPackages = pkgs: hpkgs:
      concat.lib.cabalProject2nix
      ./cabal.project
      pkgs
      hpkgs
      (old: {
        configureFlags = old.configureFlags ++ ["--ghc-options=-Werror"];
      });
  in
    {
      schemas = {
        inherit
          (flaky.schemas)
          overlays
          homeConfigurations
          packages
          devShells
          projectConfigurations
          checks
          formatter
          ;
      };

      # see these issues and discussions:
      # - NixOS/nixpkgs#16394
      # - NixOS/nixpkgs#25887
      # - NixOS/nixpkgs#26561
      # - https://discourse.nixos.org/t/nix-haskell-development-2020/6170
      overlays = {
        default =
          concat.lib.overlayHaskellPackages
          supportedGhcVersions
          self.overlays.haskell;

        haskell = concat.lib.haskellOverlay cabalPackages;
      };

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (flaky.lib.homeConfigurations.example
            pname
            self
            [
              ({pkgs, ...}: {
                home.packages = [
                  (pkgs.haskellPackages.ghcWithPackages (hpkgs: [
                    hpkgs.${pname}
                  ]))
                ];
              })
            ])
          supportedSystems);
    }
    ## NB: This uses `eachSystem defaultSystems` instead of `eachDefaultSystem`
    ##     because users often have to locally replace `defaultSystems` with
    ##     their specific system to avoid issues with IFD.
    // flake-utils.lib.eachSystem supportedSystems
    (system: let
      pkgs = import nixpkgs {
        inherit system;
        ## NB: This uses `self.overlays.default` because packages need to
        ##     be able to find other packages in this flake as dependencies.
        overlays = [self.overlays.default];
      };

      ## TODO: Extract this automatically from `pkgs.haskellPackages`.
      defaultCompiler = "ghc928";
    in {
      packages =
        {default = self.packages.${system}."${defaultCompiler}_all";}
        // concat.lib.mkPackages pkgs supportedGhcVersions cabalPackages;

      devShells =
        {default = self.devShells.${system}.${defaultCompiler};}
        // concat.lib.mkDevShells
        pkgs
        supportedGhcVersions
        cabalPackages
        (hpkgs: [
          hpkgs.haskell-language-server
          pkgs.cabal-install
          pkgs.graphviz
        ]);

      projectConfigurations =
        flaky.lib.projectConfigurations.default {inherit pkgs self;};

      checks = self.projectConfigurations.${system}.checks;
      formatter = self.projectConfigurations.${system}.formatter;
    });

  inputs = {
    bash-strict-mode = {
      inputs = {
        flaky.follows = "flaky";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/bash-strict-mode";
    };

    # Currently contains our Haskell/Nix lib that should be extracted into its
    # own flake.
    concat = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:compiling-to-categories/concat";
    };

    flake-utils.url = "github:numtide/flake-utils";

    flaky = {
      inputs = {
        bash-strict-mode.follows = "bash-strict-mode";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/flaky";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
  };
}
