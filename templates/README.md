# Nix templates

These directories contain templates for getting started with various types of projects.

`nix flake init -t flaky#<project-type>` will copy the template to your current directory. Unfortunately, due to limitations with Nix flakes, they’re less templates and more skeletons. The skeletons use [Mustache](https://mustache.github.io/) templating, which can be manually replaced by grepping for `{{` to replace with the values for your project (or use one of the implementations listed on the [Mustache](https://mustache.github.io/) site, like [Handlebars](https://handlebarsjs.com/)).

## usage

Flakes benefit from a [Git](https://git-scm.com/) repo, so the usual way to set up a new project is

```bash
mkdir -p <project-path>
cd <project-path>
git init
nix flake init "flaky#<project-type>"
```

This will automatically add all of the template files to the new repository, but not stage any of the contents.

The templates then contain [Mustache](http://mustache.github.io/)-style templating, which can either be auto-populated with Mustache or a related tool, or can be manually replaced by searching for `{{.*?}}`.

### syncing changes to the templates

If you have created projects with a template, the template may have changed since then. and it can be difficult to keep them in sync as things diverge. This can be eased a bit with `sync-template`.

Simply run

```bash
nix run flaky#sync-template -- <name of template>
```

to have the latest template files updated in your repo. This will automatically apply `mustache` if you have a .config/mustache.yaml file in your repo. Also, since it overwrites files in ways you may not like, it’s best to do this in a clean work tree. After running it, the changes can be manually evaluated.

## new templates

To create a new template here, `init` the `default` template as a starting point (or one of the other existing templates that may be closer to your project type). Then add an entry to `templates` in ../flake.nix.

## the goal

The idea is that projects should be managable by both experts in the relevant tooling (programming language, etc.) and outsiders who need to make a change or add a feature while minimizing the amount they have to learn in order to do so.

In that vein, projects generated from these templates provide traditional (e.g., language-specific) builds as well as overarching configuration via `direnv` and `nix`, which should be consistent across all projects, regardless of other tooling.

This project strives to both encompass as much project setup as possible while also minimizing the about of boilerplate necessary to create a project.

This also provides editor configuration for formatting, and other functionality.

### unwanted biases

This also currently has some biases. It defaults licensing to AGPL-3 (this could be parameterized, but the LICENSE file is harder). It's also biased toward git (`.gitignore`) and GitHub (CI provided via GitHub Actions). Since Nix is also biased toward git and GitHub, this makes sense, but hopefully we can get away from that.

## helpful tooling

These are tools that the project skeleton leverages to provide project-agnostic support.

- [direnv](https://direnv.net/) - automatically set up per-project development environments; e.g., no need to globally install build tooling for languages you rarely use
- [EditorConfig](https://editorconfig.org/) - provides some basic formatting settings in an editor-agnostic way, provided your editor supports it
- [Nix](https://nixos.org/) - reproducable builds across toolchains.

### editor-specific tooling

#### Emacs

This is what I use, so it's the most comprehensive section. This doesn't list every useful Emacs library, but just the ones that the templates take advantage of.

- [direnv](https://github.com/wbolster/emacs-direnv) or [envrc](https://github.com/purcell/envrc) - updates your Emacs environment based on the local direnv. There are tradeoffs between these two that seem to be best captured in [envrc’s design notes](https://github.com/purcell/envrc#design-notes).
- [editorconfig](https://github.com/editorconfig/editorconfig-emacs) - plugin to configure Emacs based on the project-specific EditorConfig file

## template-specific notes

These would normally be in a README in the relevant subdirectory, but that would include them in the template, which isn’t what we want.

### C

This builds with Clang, and has a rather idiosyncratic clang-format file.

### Dhall

This template prefers configuration files in Dhall format, using `dhall-nix`, `dhall-json`, `dhall-yaml`, etc. to produce the target format.

### Emacs-lisp

This template uses [Eldev](https://emacs-eldev.github.io/eldev/) to build elisp packages.

It also prefers documents (like READMEs) in [Org](https://emacs-eldev.github.io/eldev/) format instead of Markdown.

#### TODO

- package zipped source and byte-compiled files, no bare source

### Haskell

This builds using Cabal. For API-insensitivity, it also package-qualifies all imports and makes all imports either qualified or explicit.
