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

      lib = {};

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (flaky.lib.homeConfigurations.example pname self [])
          supportedSystems);
    }
    // flake-utils.lib.eachSystem supportedSystems (system: let
      pkgs = import nixpkgs {inherit system;};

      src = pkgs.lib.cleanSource ./.;
    in {
      packages = {
        default = self.packages.${system}.${pname};

        "${pname}" =
          bash-strict-mode.lib.checkedDrv pkgs
          (pkgs.stdenv.mkDerivation {
            inherit pname src;

            version = "{{project.version}}";
          });
      };

      projectConfigurations =
        flaky.lib.projectConfigurations.default {inherit pkgs self;};

      devShells =
        self.projectConfigurations.${system}.devShells
        // {default = flaky.lib.devShells.default system self [] "";};
      checks = self.projectConfigurations.${system}.checks;
      formatter = self.projectConfigurations.${system}.formatter;
    });

  inputs = {
    bash-strict-mode = {
      inputs = {
        flake-utils.follows = "flake-utils";
        flaky.follows = "flaky";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/bash-strict-mode";
    };

    flake-utils.url = "github:numtide/flake-utils";

    flaky = {
      inputs = {
        bash-strict-mode.follows = "bash-strict-mode";
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/flaky";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
  };
}
