{
  programs.direnv = {
    auto-allow = true;
    envrc = ''
      ## This gives us cascading behavior. See
      ## https://github.com/direnv/direnv/blob/master/man/direnv-stdlib.1.md#source_up_if_exists-filename
      source_up_if_exists
      use flake
    '';
  };
}
