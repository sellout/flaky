# Flaky templates & `devShells`

[![Astrolabe](https://img.shields.io/badge/Astrolabe-ready-%2300cc33?labelColor=%230033cc)](https://astrolabe.technomadic.org/)
[![built with garnix](https://img.shields.io/endpoint?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2Fsellout%2Fflaky)](https://garnix.io/repo/sellout/flaky)
[![Nix CI](https://nix-ci.com/badge/gh:sellout:flaky)](https://nix-ci.com/gh:sellout:flaky)
[![Project Manager](https://img.shields.io/badge/%20-Project%20Manager-%235277C3?logo=nixos&labelColor=%23cccccc)](https://sellout.github.io/project-manager/)

Sellout’s very opinionated personal project configuration.

## development environment

We recommend the following steps to make working in this repository as easy as possible.

### `direnv allow`

This command ensures that any work you do within this repository happens within a consistent reproducible environment. That environment provides various debugging tools, etc. When you leave this directory, you will leave that environment behind, so it doesn’t impact anything else on your system.

### `git config --local include.path ../.config/git/config`

This will apply our repository-specific Git configuration to `git` commands run against this repository. It’s lightweight (you should definitely look at it before applying this command) – it does things like telling `git blame` to ignore formatting-only commits.
