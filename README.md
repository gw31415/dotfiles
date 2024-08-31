# dotfiles and configurations for ama

## Installation

```bash
nix run github:gw31415/dotfiles
```
> [!note]
> This is just running the `dot` package. The `dot` package is a helper command to manage `gw31415/dotfiles`.

## `dot` Usage

- Switch environment (or install if not exists)
	```bash
	dot
	```

- Switch with updating the `flake.lock`
	```bash
	dot --update # or `dot -u`
	```

- Switch also with `nix-darwin` (not only `home-manager`)
	```bash
	dot --darwin
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
