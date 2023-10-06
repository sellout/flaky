{
  programs.git = {
    # automatically added to by
    config = {
      commit.template = {
        contents = "";
        path = ".config/git/template/commit.txt";
      };
    };
    hooks = {
      # post-commit = {
      #   auto-install = true;
      #   content = "";
      # };
    };
    ignores = [
      # Nix build
      "/result"
      "/source"
    ];
  };
}
