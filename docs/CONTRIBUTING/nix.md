# Contributing to Flaky Nix projects

All Flaky projects _use_ Nix, but some _are_ Nix. These guidelines apply to the latter.

**NB**: Most guidelines & justifications are in the [general contributing documentation](../CONTRIBUTING.md), this is just the Nix-specific parts, which should be considered an addendum.

## organization

In Flaky projects, most Nix code lives in the nix/ directory. That’s where overlays, packages, checks, etc. are defined.

However, for Nix-specific projects, there is also a lot of Nix code in other places. This other code is the meat of the project, which is often various modules and configurations.
