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

  project.devPackages = [
    pkgs.cabal-install
    pkgs.graphviz
    ## So cabal-plan(-bounds) can be built in a devShell, since it doesn’t
    ## work in Nix proper.
    pkgs.zlib
  ];

  programs = {
    git.ignores = [
      # Cabal build
      "dist-newstyle"
    ];
    treefmt = {
      programs.ormolu.enable = true;
      settings.formatter.prettier.excludes = ["*/docs/license-report.md"];
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
  services.flakehub.enable = false;
  services.garnix.builds."*".include =
    [
      "homeConfigurations.*"
      "nixosConfigurations.*"
    ]
    ++ flaky.lib.forGarnixSystems supportedSystems nixBuildsFor;
  services.haskell-ci = {
    ## In CI, we run without `build-depends` bounds. The cabal.project file
    ## contains any hard constraints (ones we’ve had to add to get the build
    ## matrix passing), and `cabal-plan-bounds` runs in CI to tell us if the
    ## bounds listed in the Cabal package files are still correct.
    allowNewer = true;
    allowOlder = true;
    extraCabalArgs = [
      ## Make sure we’re building everything.
      "--enable-benchmarks"
      "--enable-tests"
    ];
    ## https://docs.github.com/en/actions/reference/runners/github-hosted-runners#standard-github-hosted-runners-for-public-repositories
    ## for the current list of available runners.
    systems = [
      "macos-15" #         aarch64-darwin
      ## NB: This is the final x86_64-darwin image that GitHub will provide, and
      ##     it will be available through August 2027. See
      ##     actions/runner-images#13045 for details.
      "macos-15-intel" #   x86_64-darwin
      "ubuntu-24.04" #     x86_64-linux
      "ubuntu-24.04-arm" # aarch64-linux
      ## TODO: GHCup doesn’t install on this platform at all.
      # "windows-11-arm" #   aarch64-windows
      "windows-2025" #     x86_64-windows
    ];
  };
  services.nix-ci = {
    ## TODO: Remove this once projects have switched to Cabal.nix generation.
    allow-import-from-derivation = lib.mkForce true;
    onlyBuild = nixBuildsFor "x86_64-linux";
  };
}
