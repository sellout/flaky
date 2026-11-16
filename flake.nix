{
  description = "Shared configuration for dev environments";

  nixConfig = {
    allow-import-from-derivation = false;
    extra-substituters = ["https://sellout.cachix.org"];
    extra-trusted-public-keys = [
      "sellout.cachix.org-1:v37cTpWBEycnYxSPAgSQ57Wiqd3wjljni2aC0Xry1DE="
    ];
    ## WAIT: This should be `"fatal"`, but Nixpkgs itself violates it.
    lint-absolute-path-literals = "ignore";
    lint-short-path-literals = "fatal";
    lint-url-literals = "fatal";
    ## Isolate the build.
    sandbox = true;
    use-registries = false;
  };

  outputs = inputs: import .config/flake/outputs.nix inputs;

  inputs = {
    astrolabe-hook.url = "github:sellout/astrolabe-nix-hook";

    bash-strict-mode = {
      inputs.flaky.follows = "";
      url = "github:sellout/bash-strict-mode";
    };

    flake-utils = {
      inputs.systems.follows = "systems";
      url = "github:numtide/flake-utils";
    };

    ## The systems Garnix builds for, which `lib.forGarnixSystems` intersects
    ## with the ones a project supports.
    garnix-systems.url = "github:garnix-io/nix-systems";

    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager/release-26.05";
    };

    ## Unfortunately, there’s no channel that’s cached for both Darwin & Linux.
    ## Both `nixos-<version>` and `nixpkgs-<version>-darwin` track the
    ## `release-<version>` branch, which means the caches will generally
    ## coincide. Neither one consistently lags the other, so we bias for Darwin,
    ## because it’s typically faster & cheaper to build Linux derivations. A
    ## repo that doesn’t support Darwin might replace this with
    ## `nixos-<version>` for slightly better cache hits.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    project-manager = {
      inputs.flaky.follows = "";
      url = "github:sellout/project-manager";
    };

    ## See https://github.com/nix-systems/nix-systems#readme for an explanation
    ## of this input.
    systems.url = "github:sellout/nix-systems";
  };
}
