import { parseArgs } from "node:util";
import { $ } from "jsr:@david/dax";
import { consola } from "npm:consola";
import { highlight } from "npm:cli-highlight";

function eq(arr1: string[], arr2: string[]) {
	return arr1.length === arr2.length && arr1.every((v, i) => v === arr2[i]);
}

const darwin = Deno.build.os === "darwin";

const argv = parseArgs({
	options: {
		update: {
			type: "boolean",
			short: "u",
		},
		darwin: {
			type: "boolean",
		},
		aggressive: {
			type: "boolean",
		},
	},
	allowPositionals: true, // Subcommands
	tokens: true,
});

if (!darwin && argv.values.darwin) {
	consola.warn(
		"nix-darwin is not supported on this system. Ignoring the flag.",
	);
}

try {
	{
		// Check if the positional arguments are correctly positioned
		const pos_index = argv.tokens
			.filter((x) => x.kind === "positional")
			.map((x) => x.index)
			.sort();
		const pos_count = pos_index.length;
		if (pos_count !== 0 && pos_count !== pos_index[pos_count - 1] + 1) {
			throw "Arguments are not correctly positioned.";
		}
	}

	const configHome = $.path(
		Deno.env.get("XDG_CONFIG_HOME") || `${Deno.env.get("HOME")}/.config`,
	);
	const homeManagerPath = configHome.join("home-manager");
	const envnix = homeManagerPath.join("env.nix");
	const installed = homeManagerPath.join("flake.nix").existsSync();

	////////////////////////////////////////
	// Subcommands & Default
	////////////////////////////////////////
	if (eq(argv.positionals, ["sh"])) {
		////////////////////////////////////////
		// SHELL with Changed Directory
		////////////////////////////////////////
		if (Deno.env.get("DOT_CHILD_PS")) {
			consola.warn("You are already in a dot-child-shell.");
			Deno.exit(1);
		}
		consola.info("Entering the dot-child-shell...");
		await $`${Deno.env.get("SHELL") ?? "/bin/bash"}`
			.cwd(homeManagerPath)
			.env("DOT_CHILD_PS", "1");
	} else if (eq(argv.positionals, ["gc"])) {
		////////////////////////////////////////
		// Clean up
		////////////////////////////////////////
		consola.info("Cleaning up...");
		if (argv.values.aggressive) {
			await $`nix-collect-garbage -d`;
			consola.success("Cleaned up aggressively.");
		} else {
			await $`nix store gc -v`;
			consola.success("Cleaned up.");
		}
	} else if (eq(argv.positionals, [])) {
		////////////////////////////////////////
		// Installation & Switching
		////////////////////////////////////////
		if (!installed) {
			consola.box("dot by @gw31415");
			consola.info("GitHub: https://github.com/gw31415/dotfiles");

			consola.info("Starting the setup process...");
			consola.info("Checking the environment...");

			// Check if Nix is installed
			if (!$.commandExistsSync("nix")) {
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
			if (homeManagerPath.existsSync()) {
				throw `The target path ${homeManagerPath} already exists. Please remove it first.`;
			}

			consola.info("Cloning the dotfiles...");
			configHome.mkdirSync();
			await $`nix run nixpkgs#git -- clone https://github.com/gw31415/dotfiles ${homeManagerPath}`;
			consola.success(`Downloaded dotfiles to ${homeManagerPath}.`);

			console.log("");
			console.log(`> ${envnix}`);
			console.log(
				highlight(
					await Deno.readTextFile(homeManagerPath.join("env.nix").toString()),
					{
						language: "nix",
						ignoreIllegals: false,
					},
				),
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
					homeManagerPath.removeSync({ recursive: true });
					consola.info("Removed the downloaded dotfiles.");
				} else {
					consola.info(
						`Please edit ${envnix} and re-run the script to continue the installation.`,
					);
				}
			}
		}
		if (argv.values.update) {
			consola.info("Updating flake.lock...");
			await $`nix flake update ${homeManagerPath}`;
			consola.success(`Updated ${homeManagerPath.join("flake.lock")}.`);
		}

		// Installing/Upgrading home-manager and initial sync
		consola.info("Switching home-manager...");
		const res = await $`nix run nixpkgs#home-manager -- switch`;
		if (res.code === 0) {
			consola.success("Success.");
		} else {
			throw `Failed to ${installed ? "update" : "install"} home-manager.`;
		}
		if (darwin && argv.values.darwin) {
			consola.info("Switching darwin-rebuild...");
			await $`nix run github:LnL7/nix-darwin -- switch --flake ${homeManagerPath}`;
			consola.success("Success.");
		}
	} else {
		throw "Unknown subcommand.";
	}
} catch (e) {
	if (typeof e === "string") {
		consola.error(e);
	} else {
		consola.error("Unknown error", e);
		consola.info(
			"Please tell us about the error on GitHub: https://github.com/gw31415/dotfiles/issues",
		);
	}
	Deno.exit(1);
}
