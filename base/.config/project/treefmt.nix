{pkgs, ...}: {
  programs.treefmt = {
    ## NB: Treefmt 2 formats “hidden” files, which are ignored by the default
    ##     version. See numtide/treefmt-nix#228.
    package = pkgs.treefmt2;
    projectRootFile = "flake.nix";
    programs = {
      ## Nix formatter
      alejandra.enable = true;
      dhall.lint = true;
      ## Web/JSON/Markdown/TypeScript/YAML formatter
      prettier.enable = true;
      ## Shell formatter
      ## NB: This has to be unset to allow the .editorconfig settings to be
      ##     used. See numtide/treefmt-nix#96.
      shfmt.indent_size = null;
    };
  };
}
