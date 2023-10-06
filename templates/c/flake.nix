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
    sandbox = true;
  };

  outputs = inputs: let
    pname = "{{project.name}}";
  in
    {
      schemas = {
        inherit (inputs.project-manager.schemas)
          overlays
          homeConfigurations
          # lib
          packages
          devShells
          projectConfigurations
          checks
          formatter;
      };

      overlays.default = final: prev: {};

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (inputs.flaky.lib.homeConfigurations.example pname inputs.self [])
          inputs.flake-utils.lib.defaultSystems);

      lib = {};
    }
    // inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import inputs.nixpkgs {inherit system;};

      src = pkgs.lib.cleanSource ./.;

      ## TODO: This _should_ be done with an overlay, but I can’t seem to avoid
      ##       getting infinite recursion with it.
      stdenv = pkgs.llvmPackages_16.stdenv;
    in {
      packages = {
        default = inputs.self.packages.${system}.${pname};

        "${pname}" =
          ## TODO: Doesn’t use `strict-bash` because `libtoolize` has some bad
          ##       behavior.
          inputs.bash-strict-mode.lib.shellchecked pkgs
          (stdenv.mkDerivation {
            inherit pname src;

            buildInputs = [
              pkgs.autoreconfHook
            ];

            version = "{{project.version}}";
          });
      };

      devShells = inputs.self.projectConfigurations.${system}.devShells;

      projectConfigurations = inputs.flaky.lib.projectConfigurations.default {
        inherit pkgs;
        inherit (inputs) self;
      };

      checks = inputs.self.projectConfigurations.${system}.checks
               // {
        ## TODO: This doesn’t quite work yet.
        c-lint =
          inputs.flaky.lib.checks.simple
          pkgs
          src
          "clang-tidy"
          [pkgs.llvmPackages_16.clang]
          ''
            ## TODO: Can we keep the compile-commands.json from the original
            ##       build? E.g., send it to a separate output, which we depend
            ##       on from this check. We also want it for clangd in the
            ##       devShell.
            make clean && bear -- make
            find "$src" \( -name '*.c' -o -name '*.cpp' -o -name '*.h' \) \
              -exec clang-tidy {} +
          '';
      };

      formatter = inputs.self.projectConfigurations.${system}.formatter;
    });

  inputs = {
    bash-strict-mode = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:sellout/bash-strict-mode";
    };

    flake-utils.url = "github:numtide/flake-utils";

    flaky.url = "github:sellout/flaky";

    nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";

    project-manager = {
      inputs = {
        bash-strict-mode.follows = "bash-strict-mode";
        flaky.follows = "flaky";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/project-manager";
    };
  };
}
