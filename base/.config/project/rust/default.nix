{pkgs, ...}: {
  imports = [
    ./..
  ];

  ## TODO: Share this with github:sellout/flaky-environments#rust
  ## TODO: Remove the parts of this that are implied by `inputsFrom`.
  project.devPackages = [
    pkgs.cargo
    pkgs.cargo-fuzz
    pkgs.cargo-public-api #    to view & compare the public interface
    pkgs.cargo-semver-checks # to check version bumps & changelog
    pkgs.rust-analyzer
    pkgs.rustPackages.clippy
    pkgs.rustc
  ];

  ## formatting
  programs.treefmt.programs = {
    ## TODO: Set `rustfmt.edition` from the Rust toolchain.
    rustfmt.enable = true;
    toml-sort.enable = true;
  };
}
