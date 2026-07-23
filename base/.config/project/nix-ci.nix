{
  config,
  lib,
  ...
}: {
  services.nix-ci = {
    ## WAIT: I would ideally have this inherit it from the flake’s `nixConfig`,
    ##       but that isn’t accesiible or abstractable. Unfortunately, all of
    ##       our projects currently need it on anyway, to avoid cases that would
    ##       otherwise require `__noChroot`.
    allow-import-from-derivation = true;
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
