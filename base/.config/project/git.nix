{
  programs.git = {
    config.commit.template = {
      contents = "";
      path = ".config/git/template/commit.txt";
    };
    hooks.pre-push.text = ''
      #!/usr/bin/env bash

      nix flake check
    '';
    ignores = [
      # Nix build
      "/result"
      "/source"
    ];
    installConfig = true;
  };
}
