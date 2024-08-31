# dotfiles and configurations for ama

## Installation

```bash
nix run github:gw31415/dotfiles
```
> [!note]
> This is just running the `dot` package. The `dot` package is a helper command to manage `gw31415/dotfiles`.

## `dot` Usage

- Shortcut for `dot --home`, or install `gw31415/dotfiles`.
	```bash
	dot
	```

- Switch env of home-manager
	```bash
	dot --home # or `dot -h`
	```

- Switch env `nix-darwin` (not only `home-manager`)
	```bash
	dot --darwin # or `dot -d`
	```

- Switch with updating the `flake.lock`
	```bash
	dot --update # or `dot -u`
	```

- Switch all envs
	```bash
	dot --all # or `dot -a`
	```

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
