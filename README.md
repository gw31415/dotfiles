# dotfiles and configurations for ama

> [!warning]
> This version depends on the project [`gw31415/rsplug.nvim`](https://github.com/gw31415/rsplug.nvim), which is currently private.

## Installation

```bash
nix run github:gw31415/dotfiles
```

## Docker

```bash
nix build .#packages.x86_64-linux.dockerImage
docker load < result
docker run --rm -it ama-home-manager:latest
```

The image is built directly by Nix from `.#packages.<system>.dockerImage`, using the `ama-linux-container-*` Home Manager configuration and a small Nix-built runtime root. The image bakes the generated Home Manager profile into `/home/ama`, then starts `fish -l` directly without running `home-manager` at container startup. This output is exposed only for Linux systems; if you want another architecture, switch `x86_64-linux` to the target Linux system such as `aarch64-linux`.

For mutable container bootstrap tasks that should stay out of the Nix build, use [bootstrap-published-container.sh](/Users/ama/.config/home-manager/.github/scripts/bootstrap-published-container.sh:1). The GitHub Actions workflow runs it once against the loaded image, then commits the mutated container filesystem back into the image before pushing it.

### GitHub Container Registry

Pushes to GitHub also build and publish the image with GitHub Actions via [publish-container.yml](/Users/ama/.config/home-manager/.github/workflows/publish-container.yml:1). The workflow builds `.#packages.x86_64-linux.dockerImage`, loads it into Docker, runs the mutable bootstrap script once to populate `~/.config/home-manager` and execute extra setup commands, then pushes these tags to `ghcr.io/gw31415/ama-home-manager`:

- `latest` on pushes to `main`
- `sha-<commit sha>` on every push
- `<branch>` or `<tag>` using the pushed ref name

> [!note]
> This is just running [the `dot` package](https://github.com/gw31415/dot-cli). The `dot` package is a helper command to manage `gw31415/dotfiles`.

### macFUSE

[macFUSE](https://macfuse.github.io) needs to change the [`Security Policy`](https://github.com/macfuse/macfuse/wiki/Getting-Started).

## Sources

Package sources with fixed hashes are managed by `nvfetcher`.

```bash
nix run .#update-sources
```

## `dot` Usage

### Switching (update/upgrade) Environments

- Shortcut for `dot --home`, or install `github:gw31415/dotfiles`.
	```bash
	dot
	```

- Switch env of home-manager
	```bash
	dot --home # or `dot -h`
	```

- Switch env of nix-darwin
	```bash
	dot --darwin # or `dot -d`
	```

- Switch all envs
	```bash
	dot --all # or `dot -a`
	```

- Fetch & update the `flake.lock`
	```bash
	dot --update # or `dot -u`
	```

### Utilities

- Open the dir-changed devShell of the dotfiles and run `<cmd>`. Without `<cmd>`, it will open `$SHELL`.
	```bash
	dot sh <cmd>
	```

- Nix garbage-collection
	```bash
	dot gc
	```

- Nix garbage-collection (aggressive)
	```bash
	dot gc --aggressive
	```

## Examples

- Update all environments after updating the `flake.lock`
	```bash
	dot -ua
	```

- Show `git status` of the current `dotfiles`
	```bash
	dot sh git status
	```
