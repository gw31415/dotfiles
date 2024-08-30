import { $ } from "jsr:@david/dax";
import { consola } from "npm:consola";
import { highlight } from "npm:cli-highlight";

const homeManagerPath = $.path(
	Deno.env.get("XDG_CONFIG_HOME") || `${Deno.env.get("HOME")}/.config`,
).join("home-manager");
const envnix = homeManagerPath.join("env.nix");

const installed = envnix.existsSync();

try {
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
		const configHome = $.path(
			Deno.env.get("XDG_CONFIG_HOME") || `${Deno.env.get("HOME")}/.config`,
		);

		const homeManagerPath = configHome.join("home-manager");
		consola.info(`Installing path: ${homeManagerPath}`);

		// Cloning the dotfiles
		if (homeManagerPath.existsSync()) {
			throw `The target path ${homeManagerPath} already exists. Please remove it first.`;
		}

		consola.info("Cloning the dotfiles...");
		configHome.mkdirSync();
		await $`nix run nixpkgs#git -- clone https://github.com/gw31415/dotfiles ${homeManagerPath}`;
		consola.success(`Downloaded dotfiles to ${homeManagerPath}.`);

		const envnix = homeManagerPath.join("env.nix");
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
				(
					await consola.prompt(`Do you want to clean ${homeManagerPath}?`, {
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
					})
				).value === "remove";

			if (remove) {
				homeManagerPath.removeSync({ recursive: true });
				consola.info("Removed the downloaded dotfiles.");
			} else {
				consola.info(
					`Please edit ${envnix} and re-run the script to continue the installation.`,
				);
			}
			Deno.exit(0);
		}
	}
	// Installing home-manager and initial sync
	const res = await $`nix run nixpkgs#home-manager -- switch`;
	if (res.code === 0) {
		consola.success("Success.");
	} else {
		throw `Failed to ${installed ? "update" : "install"} home-manager.`;
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