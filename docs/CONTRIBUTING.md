---
title: "How to Contribute"
permalink: /CONTRIBUTING
---

# How to Contribute

**NB**: This is a guide to contributing to many different projects in different languages. For most projects that link here, it should be fairly comprehensive, but make sure you check for a CONTRIBUTING.md in that project for anything that may contradict the general guidelines here.

See language-specific adjustments to these guidelines

- [Haskell](./CONTRIBUTING/haskell.md)
- [Nix](./CONTRIBUTING/nix.md)

## behave

See our [code of conduct](./CODE_OF_CONDUCT.md) for details of what that means.

## reporting issues

Open anything on the forge you’re viewing the code on (most likely GitHub).

All contributions are welcome, we love improvements to docs and tests.

## building

Especially if you are unfamiliar with the particular language ecosystem, there is a Nix build (both with and without a flake). If you are unfamiliar with Nix, [Nix adjacent](...) can help you get things working in the shortest time and least effort possible.

### if you have `nix` installed

`nix build` will build and test the project fully.

`nix develop` will put you into an environment where the traditional build tooling works. If you also have `direnv` installed, then you should automatically be in that environment when you're in a directory in this project.

## development

### environment

We recommend the following steps to make working in this repository as easy as possible.

#### `direnv allow`

This command ensures that any work you do within this repository is done within a consistent reproducible environment. That environment provides various debugging tools, etc. When you leave this directory, you will leave that environment behind, so it doesn’t impact anything else on your system.

#### `git config --local include.path ../.config/git/config`

This will apply our repository-specific Git configuration to `git` commands run against this repository. It’s lightweight (you should definitely look at it before applying this command) – it does things like telling `git blame` to ignore formatting-only commits.

## making changes

### embrace the graph

There is no rebasing here.. You branch where you branch and resolve conflicts in a merge commit.

### all code is auto-formatted

Running `nix fmt` should keep your changes in line with the rest of the repository. CI will tell you if that hasn’t happened. We recommend ensuring that each commit is formatted, to keep reformatting noise out of other changes.

If you do need to bulk re-format (e.g., you have a long series of commits, and the work to modify them all, reformatting and resolving conflicts, would be onerous) then make a separate commit that _only_ formats, then another small commit adding the previous SHA to `"${repo_root}/.config/git/ignoreRevs"`.

### be conscious of versioning

Breaking changes should be made in separate PRs from backward compatible changes as much as possible.

For example, if you are adding a new API that replaces an existing one, there should first be a PR that adds the new API alongside the old one, then a second PR that removes the old API. If there are name conflicts, defer them until the breaking change, making the work to adjust to the breaking change minimal. E.g.,

You have original code like:

```
Foo.MyAPI
  call1
  call2
```

then you want to have a new API that replaces call2 and replaces call1 with call3, so you add

```
Foo.MyAPI
  call2'
  call3
```

and mark `call1` and `call2` deprecated.

Then in the breaking change, you remove `call1` and `call2`, then rename `call2'` to `call2` and define `call2'` as a deprecated alias for `call2`. Then a _later_ breaking change will remove `call2'`.

If the API is undergoing more significant changes, then rather than having them live in one place, you can put it in an adjacent module. Starting from the same original code, you add

```
Foo.MyAPI'
  call2
  call3
```

then in the breaking change, you remove `Foo.MyAPI`, rename `Foo.MyAPI'` to `Foo.MyAPI`, and make `Foo.MyAPI'` an alias to `Foo.MyAPI` with deprecated re-exports of everything it had. No future additions to `Foo.MyAPI` should be exposed via the `Foo.MyAPI'` alias.

If there are no conflicts in the changes, simply adding and removing, then there is no need for the third (future) PR. The initial two PRs will suffice.

See [the README](./README.md#versioning) for more specific information on what kind of changes are considered “breaking”.
