{
  programs.direnv = {
    auto-allow = true;
    envrc = ''
      use flake
    '';
  };
}
