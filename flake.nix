{
  description = "Shared configuration for dev environments";

  nixConfig = {
    ## NB: This is a consequence of using `self.pkgsLib.runEmptyCommand`, which
    ##     allows us to sandbox derivations that otherwise can’t be.
    allow-import-from-derivation = true;
    extra-substituters = ["https://sellout.cachix.org"];
    extra-trusted-public-keys = [
      "sellout.cachix.org-1:v37cTpWBEycnYxSPAgSQ57Wiqd3wjljni2aC0Xry1DE="
    ];
    ## WAIT: This should be `"fatal"`, but Nixpkgs itself violates it.
    lint-absolute-path-literals = "ignore";
    lint-short-path-literals = "fatal";
    lint-url-literals = "fatal";
    ## Isolate the build.
    sandbox = "relaxed";
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

    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager/release-26.05";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/release-26.05";

    project-manager = {
      inputs.flaky.follows = "";
      url = "github:sellout/project-manager";
    };

    ## See https://github.com/nix-systems/nix-systems#readme for an explanation
    ## of this input.
    systems.url = "github:sellout/nix-systems";
  };
}
