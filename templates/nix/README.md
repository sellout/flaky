# {{project.name}}

{{project.description}}

## building

## building & development

Especially if you are unfamiliar with the {{type.name}} ecosystem, there is a Nix build (both with and without a flake). If you are unfamiliar with Nix, [Nix adjacent](...) can help you get things working in the shortest time and least effort possible.

### if you have `nix` installed

`nix build` will build and test the project fully.

`nix develop` will put you into an environment where the traditional build tooling works. If you also have `direnv` installed, then you should automatically be in that environment when you're in a directory in this project.

{{#build}}
### traditional build

{{!describe language-specific build instructions, including benchmarking,
testing, etc.}}
{{description}}
{{/build}}
## versioning

In the absolute, almost every change is a breaking change. This section describes how we mitigate that to provide minor updates and revisions.

{{versioning-description}}

## comparisons

Other projects similar to this one, and how they differ.
