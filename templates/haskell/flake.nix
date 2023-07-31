{
  description = "{{project.description}}";

  nixConfig = {
    ## https://github.com/NixOS/rfcs/blob/master/rfcs/0045-deprecate-url-syntax.md
    extra-experimental-features = ["no-url-literals"];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
    extra-trusted-substituters = ["https://cache.garnix.io"];
    ## Isolate the build.
    registries = false;
    sandbox = true;
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
  outputs = inputs: let
    pname = "{{project.name}}";

    supportedGhcVersions = [
      # "ghc884" # dependency compiler-rt-libc is broken in nixpkgs 23.05
      "ghc8107"
      "ghc902"
      "ghc928"
      "ghc945"
      "ghc961"
      # "ghcHEAD" # doctest doesn’t work on current HEAD
    ];

    cabalPackages = pkgs: hpkgs:
      inputs.concat.lib.cabalProject2nix
      ./cabal.project
      pkgs
      hpkgs
      (old: {
        configureFlags = old.configureFlags ++ ["--ghc-options=-Werror"];
      });
  in
    {
      # see these issues and discussions:
      # - NixOS/nixpkgs#16394
      # - NixOS/nixpkgs#25887
      # - NixOS/nixpkgs#26561
      # - https://discourse.nixos.org/t/nix-haskell-development-2020/6170
      overlays = {
        default =
          inputs.concat.lib.overlayHaskellPackages
          supportedGhcVersions
          inputs.self.overlays.haskell;

        haskell = inputs.concat.lib.haskellOverlay cabalPackages;
      };

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (inputs.flaky.lib.homeConfigurations.example
            pname
            [({pkgs, ...}: {
              home.packages = [
                (pkgs.haskellPackages.ghcWithPackages (hpkgs: [
                  hpkgs.{{project.name}}
                ]))
              ];
            })])
          inputs.flake-utils.lib.defaultSystems);
    }
    ## NB: This uses `eachSystem defaultSystems` instead of `eachDefaultSystem`
    ##     because users often have to locally replace `defaultSystems` with
    ##     their specific system to avoid issues with IFD.
    // inputs.flake-utils.lib.eachSystem ["aarch64-darwin"]
    (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        ## NB: This uses `inputs.self.overlays.default` because packages need to
        ##     be able to find other packages in this flake as dependencies.
        overlays = [inputs.self.overlays.default];
      };

      src = pkgs.lib.cleanSource ./.;

      format = inputs.flaky.lib.format pkgs {
          programs = {
            ## Haskell linter
            hlint.enable = true;
            ## Haskell formatter
            ormolu.enable = true;
          };
        };

      ## TODO: Extract this automatically from `pkgs.haskellPackages`.
      defaultCompiler = "ghc928";
    in {
      packages =
        {default = inputs.self.packages.${system}."${defaultCompiler}_all";}
        // inputs.concat.lib.mkPackages pkgs supportedGhcVersions cabalPackages;

      devShells =
        {default = inputs.self.devShells.${system}.${defaultCompiler};}
        // inputs.concat.lib.mkDevShells
        pkgs
        supportedGhcVersions
        cabalPackages
        (hpkgs: [
          hpkgs.haskell-language-server
          pkgs.cabal-install
          pkgs.graphviz
        ]);

      checks.format = format.check inputs.self;

      formatter = format.wrapper;
    });

  inputs = {
    bash-strict-mode = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:sellout/bash-strict-mode";
    };

    # Currently contains our Haskell/Nix lib that should be extracted into its
    # own flake.
    concat = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:compiling-to-categories/concat";
    };

    flake-utils.url = "github:numtide/flake-utils";

    flaky.url = "github:sellout/flaky";

    nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";
  };
}