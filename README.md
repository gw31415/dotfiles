# dotfiles and configurations for ama

> [!warning]
> This version depends on the project [`gw31415/rsplug.nvim`](https://github.com/gw31415/rsplug.nvim), which is currently private.

## Installation

```bash
nix run github:gw31415/dotfiles
```

> [!note]
> This is just running [the `dot` package](https://github.com/gw31415/dot-cli). The `dot` package is a helper command to manage `gw31415/dotfiles`.

### macFUSE

[macFUSE](https://macfuse.github.io) needs to change the [`Security Policy`](https://github.com/macfuse/macfuse/wiki/Getting-Started).

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
