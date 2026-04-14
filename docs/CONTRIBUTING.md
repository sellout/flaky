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

### terminology

| generic    | Haskell       | Nix        | Rust      | versioned |
|------------|---------------|------------|-----------|-----------|
| repository |               |            |           | ✔         |
| project    | Cabal project | flake      | workspace |           |
| package    | Cabal package | derivation | crate     | ✔         |
| component  | Cabal stanza  |            |           |           |

There is usually one project per repository, but sometimes a project may be split across multiple repositories. It’s unlikely that more than one project would be in the same repository.

In some languages, there is a notion of a “component”. Components all share a single version. In general, we put multiple components into separate packages – for example, in Haskell, a library and an executable each represent a component, but in order to allow them to be versioned independently, they’re separated. However, test suites for a library are separate components, but kept in the same package as the library[^1], because there’s no benefit to versioning them separately.

[^1]: There’s actually a common problem that sometimes makes its difficult to keep some test suites in the same component, where you want a separately-versioned _testing_ library, and so your test suites move into the testing library’s package instead of the tested library’s package.

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

For example, if you are adding a new API that replaces an existing one, there should first be a PR that adds the new API alongside the old one, then a second PR that removes the old API. If there are name conflicts, defer them until the breaking change, making the work to adjust to the breaking change minimal. For example,

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

#### security fixes are an exception to semantic versioning

To help ensure security fixes are propagated quickly, they should

1. ideally be handled as no more than a compatible (minor) change;
2. be immediately backported to any major version chain where the latest release contains the security issue; and
3. deprecate any releases that contain the security issue.

If it’s not possible to fix the security issue without breaking the API, it should _still_ be released as a compatible change. This is an unfortunate situation, but it ensures that anyone who uses that functionality downstream faces breakage instead of insecure behavior.

### documentation

#### _correct_ is important, _pretty_ is nice

Feel free to submit changes to documentation that include assumptions, etc. that may not be correct. That’s just more evidence that additional documentation is necessary. We’ll get to correct during code review.

However, while we might mention style issues in code review, fixing that is almost never a blocker for merging a change[^2].

[^2]: There _are_ cases where formatting can block a merge. For example, if ASCII art isn’t in a code block, the rendering as re-flowed text could make it wrong or misleading. That would be a blocker.

The style is mostly adapted from, [The Elements of Typographic Style](https://en.wikipedia.org/wiki/The_Elements_of_Typographic_Style), translated to low-fidelity tools (like Markdown). But you don’t need to be familiar with that to submit acceptable docs.
