{
  description = "{{project.summary}}";

  nixConfig = {
    # https://github.com/NixOS/rfcs/blob/master/rfcs/0045-deprecate-url-syntax.md
    extra-experimental-features = ["no-url-literals"];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
    extra-trusted-substituters = ["https://cache.garnix.io"];
    # Isolate the build.
    registries = false;
    sandbox = true;
  };

  outputs = inputs: let
    pname = "{{project.name}}";
  in
    {
      overlays.default = final: prev: {};

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (inputs.flaky.lib.homeConfigurations.example pname inputs.self [])
          inputs.flake-utils.lib.defaultSystems);
    }
    // inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import inputs.nixpkgs {inherit system;};

      src = pkgs.lib.cleanSource ./.;

      format = inputs.flaky.lib.format pkgs {};
    in {
      apps = {};

      packages = {
        default = inputs.self.packages.${system}.${pname};

        "${pname}" =
          inputs.bash-strict-mode.lib.checkedDrv pkgs
          (pkgs.stdenv.mkDerivation {
            inherit pname src;

            version = "{{project.version}}";

            meta = {
              description = "{{project.summary}}";
              longDescription = ''
                {{project.description}}
              '';
            };

            nativeBuildInputs = [pkgs.bats];

            patchPhase = ''
              runHook prePatch
              patchShebangs .
              runHook postPatch
            '';

            doCheck = true;

            checkPhase = ''
              bats --print-output-on-failure ./test/all-tests.bats
            '';

            doInstallCheck = true;
          });
      };

      devShells.default =
        inputs.flaky.lib.devShells.default pkgs inputs.self [] "";

      checks.format = format.check inputs.self;

      formatter = format.wrapper;
    });

  inputs = {
    bash-strict-mode = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:sellout/bash-strict-mode";
    };

    flake-utils.url = "github:numtide/flake-utils";

    flaky.url = "github:sellout/flaky";

    nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";
  };
}
