### All available options for this file are listed in
### https://sellout.github.io/project-manager/options.xhtml
{
  config,
  flaky,
  lib,
  pkgs,
  self,
  supportedSystems,
  ...
}: let
  nixBuildsFor = sys:
    [
      "checks.${sys}.*"
      "devShells.${sys}.default"
      "packages.${sys}.default"
    ]
    ++ lib.concatMap (version: let
      ghc = self.lib.nixifyGhcVersion version;
    in [
      "devShells.${sys}.${ghc}"
      "packages.${sys}.${ghc}_all"
    ])
    (self.lib.testedGhcVersions sys);
in {
  imports = [
    ./..
    ./github-ci.nix
    ./hackage-publish.nix
  ];

  project = {
    ## This runs `cabal check` on each Cabal file, giving us some assurance that
    ## it’ll be accepted by Hackage.
    checks.cabal = pkgs.runCommand "check cabal files" {src = self;} ''
      ${lib.toShellVar "packages" config.services.haskell-ci.cabalPackages}
      any_failure=0
      trap 'any_failure=1' ERR
      set +e
      for package in "''${!packages[@]}"; do
        echo
        echo "$package"
        echo "––––––––––––––––––––––––––––––––––––––––"
        cd "$src/''${packages[$package]}"
        ${lib.getExe pkgs.cabal-install} check
      done
      set -e
      touch "$out"
      exit $any_failure
    '';

    devPackages = [
      pkgs.cabal-install
      pkgs.graphviz
      ## So cabal-plan(-bounds) can be built in a devShell, since it doesn’t
      ## work in Nix proper.
      pkgs.zlib
    ];
  };

  programs = {
    git.ignores = [
      # Cabal build
      "dist-newstyle"
    ];
    treefmt = {
      programs.ormolu.enable = true;
      ## TODO: This is conditionalized because of numtide/treefmt-nix#419. Clean
      ##       this up once that’s fixed.
      settings.formatter =
        if pkgs.stdenv.hostPlatform.system != "i686-linux"
        then {prettier.excludes = ["*/docs/license-report.md"];}
        else {};
    };
    vale = {
      excludes = [
        "*.cabal"
        "*.hs"
        "*.hs-boot"
        "*.lhs"
        "*.lhs-boot"
        "*/docs/license-report.md"
        "./cabal.project"
      ];
      vocab.${config.project.name}.accept = [
        "API"
        "bugfix"
        "comonad"
        "conditionalize"
        "formatter"
        "functor"
        "GADT"
        "Hackage"
        "inline"
        "Kleisli"
        "Kmett"
        "pragma"
        "unformatted"
        "widening"
      ];
    };
  };

  # NB: Can’t use IFD on FlakeHub (see DeterminateSystems/flakehub-push#69), so
  #     this is disabled until we have a way to build Haskell without IFD.
  services.flakehub.enable = lib.mkForce false;
  services.haskell-ci = with config.services.github.runners.latest; let
    filterGhcVersions =
      lib.intersectLists config.services.haskell-ci.ghcVersions;
  in {
    ## In CI, we run without `build-depends` bounds. The cabal.project file
    ## contains any hard constraints (ones we’ve had to add to get the build
    ## matrix passing), and `cabal-plan-bounds` runs in CI to tell us if the
    ## bounds listed in the Cabal package files are still correct.
    allowNewer = true;
    allowOlder = true;
    checkBounds.enable = lib.mkDefault true;
    extraCabalArgs = [
      ## Make sure we’re building everything.
      "--enable-benchmarks"
      "--enable-tests"
    ];
    ## https://docs.github.com/en/actions/reference/runners/github-hosted-runners#standard-github-hosted-runners-for-public-repositories
    ## for the current list of available runners.
    systems = [
      linux-arm64
      linux-x64
      macos-arm64
      macos-intel
      ## TODO: GHCup doesn’t install on this platform at all.
      # windows-arm64
      windows-x64
    ];
    exclude =
      ## GHCup needs an older Ubuntu for these versions..
      map (ghc: {
        inherit ghc;
        os = linux-x64;
      }) (filterGhcVersions ["7.10.3" "8.0.2" "8.2.2"])
      ## GitHub can’t install GHC older than 9.2 on ARM systems.
      ++ lib.concatMap (ghc:
        map (os: {
          inherit ghc os;
        }) [linux-arm64 macos-arm64])
      (builtins.filter (ghc: lib.versionOlder ghc "9.2")
        config.services.haskell-ci.ghcVersions)
      ++ [
        ## GHC 9.2.1 relied on libnuma at runtime for aarch64-linux
        ## https://gitlab.haskell.org/ghc/ghc/-/merge_requests/7357
        {
          ghc = "9.2.1";
          os = linux-arm64;
        }
      ];
    include = lib.concatMap (bounds:
      map (ghc: {
        inherit bounds ghc;
        os = linux-x64;
      }) (filterGhcVersions ["7.10.3" "8.0.2" "8.2.2"])
      ++ [
        {
          inherit bounds;
          ghc = "9.2.2";
          os = linux-arm64;
        }
      ])
    ["" "--prefer-oldest"];
  };
  services.nix-ci = {
    ## TODO: Remove this once projects have switched to Cabal.nix generation.
    allow-import-from-derivation = lib.mkForce true;
    onlyBuild = nixBuildsFor "x86_64-linux";
  };
}
