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

  outputs = inputs: let
    pname = "{{project.name}}";
    ename = "emacs-${pname}";
  in
    {
      schemas = {
        inherit
          (inputs.flaky.schemas)
          overlays
          homeConfigurations
          packages
          devShells
          projectConfigurations
          checks
          formatter
          ;
      };

      overlays = {
        default =
          inputs.flaky.lib.elisp.overlays.default inputs.self.overlays.emacs;

        emacs = final: prev: efinal: eprev: {
          "${pname}" = inputs.self.packages.${final.system}.${ename};
        };
      };

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (inputs.flaky.lib.homeConfigurations.example
            pname
            inputs.self
            [
              ({pkgs, ...}: {
                programs.emacs = {
                  enable = true;
                  extraConfig = ''
                    (require '${pname})
                  '';
                  extraPackages = epkgs: [epkgs.${pname}];
                };
              })
            ])
          inputs.flake-utils.lib.defaultSystems);
    }
    // inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [inputs.flaky.overlays.elisp-dependencies];
      };

      src = pkgs.lib.cleanSource ./.;
    in {
      packages = {
        default = inputs.self.packages.${system}.${ename};
        "${ename}" = inputs.flaky.lib.elisp.package pkgs src pname (_: []);
      };

      devShells.default =
        inputs.flaky.lib.devShells.default pkgs inputs.self [] "";

      projectConfigurations = inputs.flaky.lib.projectConfigurations.default {
        inherit pkgs;
        inherit (inputs) self;
      };

      checks =
        inputs.self.projectConfigurations.${system}.checks
        // {
          elisp-doctor = inputs.flaky.lib.elisp.checks.doctor pkgs src;
          elisp-lint = inputs.flaky.lib.elisp.checks.lint pkgs src (_: []);
        };

      formatter = inputs.self.projectConfigurations.${system}.formatter;
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

    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
  };
}
