{config, ...}: {
  services.flakehub = {
    ## TODO: Should be inferred.
    name = "sellout/${config.project.name}";
    visibility = "public";
  };
}
