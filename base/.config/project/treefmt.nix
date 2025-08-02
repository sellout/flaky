{pkgs, ...}: {
  programs.treefmt = {
    projectRootFile = "flake.nix";
    programs = {
      ## Nix formatter
      alejandra.enable = true;
      dhall.lint = true;
      ## Web/JSON/Markdown/TypeScript/YAML formatter
      ## TODO: This hangs during compile on i686-linux with Nixpkgs 25.05.
      prettier.enable = pkgs.system != "i686-linux";
      ## Shell formatter
      ## NB: This has to be unset to allow the .editorconfig settings to be
      ##     used. See numtide/treefmt-nix#96.
      shfmt.indent_size = null;
    };
  };
}
