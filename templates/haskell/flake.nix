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
    flake-utils,
    flaky,
    flaky-haskell,
    nixpkgs,
    self,
  }: let
    pname = "{{project.name}}";

    supportedSystems = flaky.lib.defaultSystems;

    cabalPackages = pkgs: hpkgs:
      flaky-haskell.lib.cabalProject2nix
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
          flaky-haskell.lib.overlayHaskellPackages
          (self.lib.supportedGhcVersions "")
          (final: prev:
            nixpkgs.lib.composeManyExtensions [
              ## TODO: I think this overlay is only needed by formatters,
              ##       devShells, etc., so it shouldn’t be included in the
              ##       standard overlay.
              (flaky.overlays.haskellDependencies final prev)
              (self.overlays.haskell final prev)
              (self.overlays.haskellDependencies final prev)
            ]);

        haskell = flaky-haskell.lib.haskellOverlay cabalPackages;

        ## NB: Dependencies that are overridden because they are broken in
        ##     Nixpkgs should be pushed upstream to Flaky. This is for
        ##     dependencies that we override for reasons local to the project.
        haskellDependencies = final: prev: hfinal: hprev: {};
      };

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (flaky.lib.homeConfigurations.example self [
            ({pkgs, ...}: {
              home.packages = [
                (pkgs.haskellPackages.ghcWithPackages (hpkgs: [hpkgs.${pname}]))
              ];
            })
          ])
          supportedSystems);

      lib = {
        ## TODO: Extract this automatically from `pkgs.haskellPackages`.
        defaultCompiler = "ghc948";

        ## Test the oldest revision possible for each minor release. If it’s not
        ## available in nixpkgs, test the oldest available, then try an older
        ## one via GitHub workflow. Additionally, check any revisions that have
        ## explicit conditionalization. And check whatever version `pkgs.ghc`
        ## maps to in the nixpkgs we depend on.
        testedGhcVersions = system:
          [
            self.lib.defaultCompiler
            "ghc8107"
            "ghc902"
            "ghc924"
            "ghc942"
            "ghc962"
            "ghc981"
            # "ghcHEAD" # doctest doesn’t work on current HEAD
          ]
          ## dependency compiler-rt-libc-7.1.0 is broken in on aarch64-darwin.
          ++ nixpkgs.lib.optional (system != "aarch64-darwin") "ghc884";

        ## The versions that are older than those supported by Nix that we
        ## prefer to test against.
        nonNixTestedGhcVersions = [
          "7.10.3"
          "8.0.2"
          "8.2.2"
          "8.4.1"
          "8.6.1"
          "8.8.1"
          "8.10.1"
          "9.0.1"
          "9.2.1"
          "9.4.1"
          "9.6.1"
          "9.8.1" # since `cabal-plan-bounds` doesn’t work under Nix
        ];

        ## However, provide packages in the default overlay for _every_
        ## supported version.
        supportedGhcVersions = system:
          self.lib.testedGhcVersions system
          ++ [
            "ghc925"
            "ghc926"
            "ghc927"
            "ghc928"
            "ghc943"
            "ghc944"
            "ghc945"
            "ghc946"
            "ghc947"
            "ghc963"
          ];
      };
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
    in {
      packages =
        {default = self.packages.${system}."${self.lib.defaultCompiler}_all";}
        // flaky-haskell.lib.mkPackages
        pkgs
        (self.lib.supportedGhcVersions system)
        cabalPackages;

      devShells =
        {default = self.devShells.${system}.${self.lib.defaultCompiler};}
        // flaky-haskell.lib.mkDevShells
        pkgs
        (self.lib.supportedGhcVersions system)
        cabalPackages
        (hpkgs:
          [self.projectConfigurations.${system}.packages.path]
          ## NB: Haskell Language Server no longer supports GHC <9.
          ## TODO: HLS also apparently broken on 9.8.1.
          ## NB: And there are some 32-bit issues on i686.
          ++ nixpkgs.lib.optional
          (nixpkgs.lib.versionAtLeast hpkgs.ghc.version "9"
            && builtins.compareVersions hpkgs.ghc.version "9.8.1" != 0
            && system != "i686-linux")
          hpkgs.haskell-language-server);

      projectConfigurations =
        flaky.lib.projectConfigurations.default {inherit pkgs self;};

      checks = self.projectConfigurations.${system}.checks;
      formatter = self.projectConfigurations.${system}.formatter;
    });

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    flaky = {
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/flaky";
    };

    flaky-haskell = {
      inputs = {
        flake-utils.follows = "flake-utils";
        flaky.follows = "flaky";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/flaky-haskell";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";
  };
}
