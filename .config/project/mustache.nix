{config, lib, ...}: {
  project.file.".config/mustache.yaml" = {
    ## TODO: Should be able to make this `"store"`.
    minimum-persistence = "worktree";
    text = lib.generators.toYAML {} {
      project = {
        inherit (config.project) name summary;
        description = ''
          Making it simpler to manage poly-repo projects (and projectiverses).
        '';
        repo = "sellout/${config.project.name}";
        version = "0.1.0";
      };
      type.name = "nix";
    };
  };
}
