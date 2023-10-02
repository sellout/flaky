# Configuration Inheritance

Some tools (like those built with [probot](https://github.com/probot/octokit-plugin-config#the-_extends-key)) can inherit settings defined in a separate repo.

This can reduce redundancy in templates, etc. so the individual projects only need to specify the places that differ.

We keep extensible files in this directory.

## use cases

### [repository-settings/app](https://github.com/repository-settings/app)

Add

```yaml
_extends: sellout/flaky:base/.github/settings.yml
```

to the “.github/settings.yml” file in your repo.
