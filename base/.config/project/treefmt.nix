{
  programs.treefmt = {
    projectRootFile = "flake.nix";
    programs = {
      ## Nix formatter
      alejandra.enable = true;
      ## Web/JSON/Markdown/TypeScript/YAML formatter
      prettier.enable = true;
    };
  };
}
