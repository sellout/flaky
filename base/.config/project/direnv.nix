{
  programs.direnv = {
    auto-allow = true;
    envrc.text = ''
      use flake
    '';
  };
}
