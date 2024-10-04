{config, ...}: {
  imports = [
    ./..
    ./clang-format.nix
  ];

  programs.vale = {
    excludes = [
      "*/Makefile.am"
      "./configure.ac"
    ];
    vocab.${config.project.name}.accept = [
      "Autotools"
      "GNU"
    ];
  };
}
