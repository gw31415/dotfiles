import { platform } from "node:os";
import { parseArgs } from "node:util";
import { $ } from "bun";
import { highlight } from "cli-highlight";
import { consola } from "consola";
import path from "node:path";
import { exists, mkdir, rm } from "node:fs/promises";

function eq(arr1: string[], arr2: string[]) {
	return arr1.length === arr2.length && arr1.every((v, i) => v === arr2[i]);
}

async function getCliPath(
	cli: string,
	fallbackNixpkg: string = cli,
): Promise<string> {
	const cliPath = Bun.which(cli);
	if (cliPath) {
		return cliPath;
	}
	const output = await $`nix path-info nixpkgs#${fallbackNixpkg}`;
	if (output.exitCode !== 0) {
		return cli;
	}
	return `${output.text()}/bin/${cli}`;
}

const darwin = platform() === "darwin";

function getArgs() {
	// parseArgs throws TypeError if unknown flags are detected
	// This function is required to properly handle Typescript types and also determine errors
	try {
		const argv = parseArgs({
			options: {
				all: {
					type: "boolean",
					short: "a",
				},
				update: {
					type: "boolean",
					short: "u",
				},
				darwin: {
					type: "boolean",
					short: "d",
				},
				home: {
					type: "boolean",
					short: "h",
				},
				aggressive: {
					type: "boolean",
				},
			},
			allowPositionals: true, // Subcommands
			tokens: true,
		});
		return argv;
	} catch (e) {
		const err: Error = e instanceof Error ? e : new Error(`${e}`);
		return err;
	}
}

(async () => {
	try {
		const args = process.argv.slice(2);
		const configHome =
			process.env.XDG_CONFIG_HOME ?? `${process.env.HOME}/.config`;
		const homeManagerPath = path.join(configHome, "home-manager"); // configHome.join("home-manager");
		const envnix = path.join(homeManagerPath, "env.nix");
		const installed = await Bun.file(
			path.join(homeManagerPath, "flake.nix"),
		).exists();

		////////////////////////////////////////
		// Subcommand: sh ... devShell
		// Special case: No need to parse the arguments
		////////////////////////////////////////

		if (args[0] === "sh") {
			if (!installed) {
				throw "Not installed. To install, please run without the subcommand first.";
			}
			if ((process.env.DOT_DEVSHELL ?? "").length > 0) {
				consola.warn("You are already in the devShell. Cancelled.");
				process.exit(1);
			}
			consola.info("Entering the devShell...");
			const cmd =
				args.length > 1
					? $`nix develop --impure -c ${args.slice(1)}`
					: $`nix develop --impure -c ${process.env.SHELL ?? "/bin/bash"}`;
			const res = await cmd
				.cwd(homeManagerPath)
				.env({ ...process.env, DOT_DEVSHELL: "1" })
				.nothrow();
			consola.info("Exiting the devShell...");
			process.exit(res.exitCode);
		}

		////////////////////////////////////////
		// Parsing Arguments
		////////////////////////////////////////
		const parsedArgs = getArgs();
		// If sh is used, Subcommand does not need to be thrown
		// because of the different parsing method
		if (parsedArgs instanceof Error) {
			if (parsedArgs instanceof TypeError) {
				throw "Unknown flags detected.";
			}
			throw parsedArgs;
		}
		if (!darwin && parsedArgs.values.darwin) {
			consola.warn(
				"nix-darwin is not supported on this system. Ignoring the flag.",
			);
		}
		{
			// Check if the positional arguments are correctly positioned
			const pos_index = parsedArgs.tokens
				.filter((x) => x.kind === "positional")
				.map((x) => x.index)
				.sort();
			const pos_count = pos_index.length;
			if (pos_count !== 0 && pos_count !== pos_index[pos_count - 1] + 1) {
				throw "Arguments are not correctly positioned.";
			}
		}

		////////////////////////////////////////
		// Subcommands & Default
		////////////////////////////////////////
		if (eq(parsedArgs.positionals, [])) {
			////////////////////////////////////////
			// Subcommand: (default) ... Installation & Switching
			////////////////////////////////////////
			if (!installed) {
				consola.box("dot by @gw31415");
				consola.info("GitHub: https://github.com/gw31415/dotfiles");

				consola.info("Starting the setup process...");
				consola.info("Checking the environment...");

				// Check if Nix is installed
				if (!Bun.which("nix")) {
					throw "Nix is not installed. Please install Nix first.";
				}
				consola.success("Nix is installed.");

				// Get Nix configuration and check experimental-features
				const experimental_features =
					await $`nix show-config | grep experimental-features`.text();

				if (!experimental_features.includes("=")) {
					throw "experimental-features is not set.";
				}

				const features = experimental_features
					.slice(experimental_features.indexOf("=") + 1)
					.split(/\s+/g)
					.filter((x) => x.length > 0);

				if (!features.includes("nix-command") || !features.includes("flakes")) {
					throw "nix-command and/or flakes are not set.";
				}
				consola.success("nix-command and flakes are set.");

				// Obtaining various variables
				consola.info(`Installing path: ${homeManagerPath}`);

				// Cloning the dotfiles
				if (await exists(homeManagerPath)) {
					throw `The target path ${homeManagerPath} already exists. Please remove it first.`;
				}

				consola.info("Cloning the dotfiles...");
				await mkdir(configHome, { recursive: true });
				await $`${await getCliPath("git")} clone https://github.com/gw31415/dotfiles ${homeManagerPath}`;
				consola.success(`Downloaded dotfiles to ${homeManagerPath}.`);

				console.log("");
				console.log(`> ${envnix}`);
				console.log(
					highlight(await Bun.file(envnix).text(), {
						language: "nix",
						ignoreIllegals: false,
					}),
				);
				console.log("");
				consola.info(
					`If the information in ${envnix} does not match, the build will fail.`,
					`You can edit ${envnix} before running the next command.`,
				);
				if (
					!(await consola.prompt("Continue installation?", {
						type: "confirm",
					}))
				) {
					const remove =
						((await consola.prompt(`Do you want to clean ${homeManagerPath}?`, {
							type: "select",
							options: [
								{
									label: `Leave ${envnix}`,
									value: "leave",
									hint: `You can edit ${envnix} and continue the installation.`,
								},
								{
									label: `Remove ${envnix}`,
									value: "remove",
									hint: "You can re-run the script to download the dotfiles again.",
								},
							],
							initial: "leave",
						})) as unknown) === "remove";
					if (remove) {
						await rm(homeManagerPath, { recursive: true, force: true });
						consola.info("Removed the downloaded dotfiles.");
					} else {
						consola.info(
							`Please edit ${envnix} and re-run the script to continue the installation.`,
						);
					}
				}
			}
			if (parsedArgs.values.update) {
				consola.info("Updating flake.lock...");
				const flakeLock = path.join(homeManagerPath, "flake.lock");
				const hash = async () =>
					Bun.hash(await Bun.file(flakeLock).arrayBuffer());
				const hashBefore = (await Bun.file(flakeLock).exists())
					? await hash()
					: "";
				await $`nix flake update --flake ${homeManagerPath}`;
				const hashAfter = await hash();
				if (hashBefore === hashAfter) {
					consola.info("No changes. Update skipped.");
				} else {
					consola.success(
						`Updated ${path.join(homeManagerPath, "flake.lock")}.`,
					);
					await $`git commit flake.lock -m "build: Update flake.lock"`.cwd(
						homeManagerPath,
					);
				}
			}

			// Installing/Upgrading home-manager and initial sync
			if (
				args.length === 0 ||
				parsedArgs.values.home ||
				parsedArgs.values.all
			) {
				consola.info("Switching home-manager...");
				const res = await $`${await getCliPath("home-manager")} switch`
					.cwd(homeManagerPath)
					.nothrow();
				if (res.exitCode !== 0) {
					// TODO: @david/dax throws an error if the command fails, so it should be handled each $-usage
					// because we need to determine if the error is a handled error or not to throw a proper error message.
					// This is a temporary solution.
					throw `Failed to ${installed ? "update" : "install"} home-manager.`;
				}
			}
			if (darwin && (parsedArgs.values.darwin || parsedArgs.values.all)) {
				consola.info("Switching darwin-rebuild...");
				const res = await $`nix run .#nix-darwin -- switch --flake .`
					.cwd(homeManagerPath)
					.nothrow();
				if (res.exitCode !== 0) {
					throw "Failed to switch darwin-rebuild.";
				}
			}
			consola.success("Success.");
			process.exit(0);
		}

		// Subcommands below is needed to be installed
		if (!installed) {
			throw "Not installed. To install, please run without the subcommand first.";
		}

		if (eq(parsedArgs.positionals, ["gc"])) {
			////////////////////////////////////////
			// Subcommand: gc ... Garbage Collection
			////////////////////////////////////////
			consola.info("Cleaning up...");
			if (parsedArgs.values.aggressive) {
				await $`nix-collect-garbage -d`;
				consola.success("Cleaned up aggressively.");
			} else {
				await $`nix store gc -v`;
				consola.success("Cleaned up.");
			}
		} else {
			throw "Unknown subcommand.";
		}
	} catch (e) {
		if (typeof e === "string") {
			consola.error(e);
		} else {
			consola.error("Unknown error");
			console.log(Bun.inspect(e, { colors: true }));
			consola.info(
				"Please tell us about the error on GitHub: https://github.com/gw31415/dotfiles/issues",
			);
		}
		process.exit(1);
	}
})();
