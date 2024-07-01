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

  outputs = {
    bash-strict-mode,
    flake-utils,
    flaky,
    nixpkgs,
    self,
  }: let
    pname = "{{project.name}}";

    supportedSystems = flaky.lib.defaultSystems;
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

      overlays.default = final: prev: {};

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (flaky.lib.homeConfigurations.example self
            [({pkgs, ...}: {home.packages = [pkgs.${pname}];})])
          supportedSystems);

      lib = {};
    }
    // flake-utils.lib.eachSystem supportedSystems (system: let
      pkgs = import nixpkgs {inherit system;};

      src = pkgs.lib.cleanSource ./.;

      ## TODO: This _should_ be done with an overlay, but I can’t seem to avoid
      ##       getting infinite recursion with it.
      stdenv = pkgs.llvmPackages_16.stdenv;
    in {
      packages = {
        default = self.packages.${system}.${pname};

        "${pname}" =
          bash-strict-mode.lib.checkedDrv pkgs
          (stdenv.mkDerivation {
            inherit pname src;

            buildInputs = [
              pkgs.autoreconfHook
            ];

            version = "{{project.version}}";
          });
      };

      projectConfigurations =
        flaky.lib.projectConfigurations.default {inherit pkgs self;};

      devShells =
        self.projectConfigurations.${system}.devShells
        // {default = flaky.lib.devShells.default system self [] "";};

      checks =
        self.projectConfigurations.${system}.checks
        // {
          ## TODO: This doesn’t quite work yet.
          c-lint =
            flaky.lib.checks.simple
            pkgs
            src
            "clang-tidy"
            [pkgs.llvmPackages_16.clang]
            ''
              ## TODO: Can we keep the compile-commands.json from the original
              ##       build? E.g., send it to a separate output, which we
              ##       depend on from this check. We also want it for clangd in
              ##       the devShell.
              make clean && bear -- make
              find "$src" \( -name '*.c' -o -name '*.cpp' -o -name '*.h' \) \
                -exec clang-tidy {} +
            '';
        };

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
