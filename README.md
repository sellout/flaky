# Flaky templates & `devShells`

[![Astrolabe](https://img.shields.io/badge/Astrolabe-ready-%2300cc33?labelColor=%230033cc)](https://astrolabe.technomadic.org/)
[![Nix CI](https://nix-ci.com/badge/gh:sellout:flaky)](https://nix-ci.com/gh:sellout:flaky)
[![Project Manager](https://img.shields.io/badge/%20-Project%20Manager-%235277C3?logo=nixos&labelColor=%23cccccc)](https://sellout.github.io/project-manager/)

Sellout’s opinionated personal project configuration.

## development environment

We recommend the following steps to make working in this repository easier.

### `direnv allow`

This command ensures that any work you do within this repository happens within a consistent reproducible environment. That environment provides debugging tools, etc. When you leave this directory, you’ll leave that environment behind, so it doesn’t impact anything else on your system.

### `git config --local include.path ../.config/git/config`

This applies our repository-specific Git configuration to `git` commands run against this repository. It’s lightweight (you should definitely look at it before applying this command) – it does things like telling `git blame` to ignore formatting-only commits.
