# Flaky templates & dev shells

Templates for Sellout’s personal projects, plus a flake `lib` to make the templates as lightweight and easy to keep in sync as possible.

This also contains dev shells to make it easy to work on projects I don’t manage (that don’t have a flake).

## usage

Optional one-time setup (this gives you a shorthand for referencing the flake later):

```bash
nix registry add flaky github:sellout/flaky
```

If you omit this step, then `flaky#` in the examples needs to be replaced with a concrete URL, generally `github:sellout/flaky#` (or `./path/to/flaky#` if you have cloned the repo.

Alternatively, if you have some other “system” flake that you do things from, then adding

```nix
{
  outputs = inputs: {
    …
    templates = inputs.flaky.templates // { … };
    …
  };

  inputs.flaky.url = "github:sellout/flaky";
}
```

should allow you to replace `flaky#` with `<my-sys-flake>#` in the examples below. This is my preferred approach – where a single flake manages everything about my various systems.

### templates

[manual](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-init.html)

```bash
mkdir -p <project-path>
cd <project-path>
git init
nix flake init flaky#<project-type>
find . -type f -exec bash -c \
  'mustache "${src}/templates/example.yaml" "$0" | sponge "$0"' \
  {} \;
nix --accept-flake-config fmt
direnv allow # if you’re a direnv user
```

These flakes support [direnv](https://direnv.net/) out of the box.

See [the templates](./templates/README.md) for more.

### dev shells

The dev shells contain a much wider array of tooling, in order to support most projects in any ecosystem.

```bash
cd <project-path>
nix develop flaky#<project-type>
```

If you use [direnv](https://direnv.net/), adding `nix develop flaky#<project-type>` to a `.envrc` in the project-path should automate this for you.

**NB**: The `default` dev shelll doesn’t correspond to the `default` template. The `default` dev shell is for developing _this_ flake, while the `default` template is an alias for the `nix` template (and thus corresponds to the `nix` dev shell).
