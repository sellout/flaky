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
    flake-utils,
    flaky,
    nixpkgs,
    self,
  }: let
    pname = "{{project.name}}";
    ename = "emacs-${pname}";
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

      overlays = {
        default = flaky.lib.elisp.overlays.default self.overlays.emacs;

        emacs = final: prev: efinal: eprev: {
          "${pname}" = self.packages.${final.system}.${ename};
        };
      };

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (flaky.lib.homeConfigurations.example
            pname
            self
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
          flake-utils.lib.defaultSystems);
    }
    // flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [flaky.overlays.elisp-dependencies];
      };

      src = pkgs.lib.cleanSource ./.;
    in {
      packages = {
        default = self.packages.${system}.${ename};
        "${ename}" = flaky.lib.elisp.package pkgs src pname (_: []);
      };

      devShells.default =
        flaky.lib.devShells.default pkgs self [] "";

      projectConfigurations =
        flaky.lib.projectConfigurations.default {inherit pkgs self;};

      checks =
        self.projectConfigurations.${system}.checks
        // {
          elisp-doctor = flaky.lib.elisp.checks.doctor pkgs src;
          elisp-lint = flaky.lib.elisp.checks.lint pkgs src (_: []);
        };

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

    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
  };
}
