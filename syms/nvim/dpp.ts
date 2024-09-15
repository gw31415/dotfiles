import type { Denops } from "jsr:@denops/core";
import * as path from "jsr:@std/path";
import * as fn from "jsr:@denops/std/function";
import { BaseConfig } from "jsr:@shougo/dpp-vim/config";
import type { Dpp } from "jsr:@shougo/dpp-vim/dpp";
import type { ContextBuilder, Plugin } from "jsr:@shougo/dpp-vim/types";

export class Config extends BaseConfig {
	override async config(args: {
		denops: Denops;
		contextBuilder: ContextBuilder;
		basePath: string;
		dpp: Dpp;
	}): Promise<{
		plugins: Plugin[];
		stateLines: string[];
	}> {
		args.contextBuilder.setGlobal({ protocols: ["git"] });

		type Toml = {
			hooks_file?: string;
			ftplugins?: Record<string, string>;
			plugins?: Plugin[];
		};

		type LazyMakeStateResult = {
			plugins: Plugin[];
			stateLines: string[];
		};

		const [context, options] = await args.contextBuilder.get(args.denops);

		const dirname = path.resolve(path.dirname(path.fromFileUrl(import.meta.url)));

		const tomlsDir = `${dirname}/toml/`;

		const tomls: Toml[] = [];
		tomls.push(
			(await args.dpp.extAction(args.denops, context, options, "toml", "load", {
				path: await fn.expand(args.denops, `${tomlsDir}plugin.toml`),
				options: {
					lazy: false,
				},
			})) as Toml,
		);

		for (const tomlFile of Deno.readDirSync(`${tomlsDir}/lazy/`)) {
			if (!tomlFile.name.endsWith(".toml")) {
				continue;
			}
			tomls.push(
				(await args.dpp.extAction(
					args.denops,
					context,
					options,
					"toml",
					"load",
					{
						path: await fn.expand(
							args.denops,
							`${tomlsDir}/lazy/${tomlFile.name}`,
						),
						options: {
							lazy: true,
						},
					},
				)) as Toml,
			);
		}

		const recordPlugins: Record<string, Plugin> = {};
		const ftplugins: Record<string, string> = {};
		const hooksFiles: string[] = [];

		for (const toml of tomls) {
			for (const plugin of toml.plugins ?? []) {
				recordPlugins[plugin.name] = plugin;
			}

			if (toml.ftplugins) {
				for (const filetype of Object.keys(toml.ftplugins)) {
					if (ftplugins[filetype]) {
						ftplugins[filetype] += `\n${toml.ftplugins[filetype]}`;
					} else {
						ftplugins[filetype] = toml.ftplugins[filetype];
					}
				}
			}

			if (toml.hooks_file) {
				hooksFiles.push(toml.hooks_file);
			}
		}

		const lazyResult = (await args.dpp.extAction(
			args.denops,
			context,
			options,
			"lazy",
			"makeState",
			{
				plugins: Object.values(recordPlugins),
			},
		)) as LazyMakeStateResult;

		console.log(lazyResult);

		return {
			plugins: lazyResult.plugins,
			stateLines: lazyResult.stateLines,
		};
	}
}
