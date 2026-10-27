{
  config,
  lib,
  ...
}: {
  services.nix-ci = {
    allow-import-from-derivation = false;
    ## Wouldn’t it be nice to not have to duplicate this between here and flake
    ## inputs? (See NixOS/nix#4945)
    cachix = {
      name = "sellout";
      public-key = "sellout.cachix.org-1:v37cTpWBEycnYxSPAgSQ57Wiqd3wjljni2aC0Xry1DE=";
    };
    fail-fast = false;
  };

  ## Nix CI only builds on x86_64-linux for now, so if we’re using it, take that
  ## weight off of garnix.
  ##
  ## NB: This doesn’t exclude the `"*.x86_64-linux""` or
  ##     `"*.x86_64-linux-example"` patterns because Nix CI doesn’t build those
  ##     yet.
  services.garnix.builds."*".exclude =
    lib.optional (config.services.nix-ci.enable != false) "*.x86_64-linux.*";
}
