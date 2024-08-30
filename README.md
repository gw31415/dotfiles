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

- Enter the dir-changed shell
	```bash
	dot sh
	```

- Nix garbage-collection
	```bash
	dot gc
	```

- Nix garbage-collection (aggressive)
	```bash
	dot gc --aggressive
	```
