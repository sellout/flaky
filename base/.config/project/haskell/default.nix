{
  config,
  flaky,
  lib,
  pkgs,
  self,
  supportedSystems,
}: {
  imports = [
    ./..
    (import ./github-ci.nix {
      inherit (self.lib) defaultGhcVersion;
      systems = self.lib.githubSystems;
      packages = {"${config.project.name}" = config.project.name;};
      latestGhcVersion = "9.10.1";
    })
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
        "*.lhs"
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

  services.garnix.builds."*".include =
    [
      "homeConfigurations.*"
      "nixosConfigurations.*"
    ]
    ++ flaky.lib.forGarnixSystems supportedSystems (sys:
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
      (self.lib.testedGhcVersions sys));
  # NB: Can’t use IFD on FlakeHub (see DeterminateSystems/flakehub-push#69), so
  #     this is disabled until we have a way to build Haskell without IFD.
  services.flakehub.enable = false;
}
