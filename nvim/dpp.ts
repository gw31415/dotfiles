import type { Denops } from "jsr:@denops/core";
import type {
  Ext as LazyExt,
  Params as LazyParams,
} from "jsr:@shougo/dpp-ext-lazy";
import type { Params as PackspecParams } from "jsr:@shougo/dpp-ext-packspec";
import type {
  Ext as TomlExt,
  Params as TomlParams,
} from "jsr:@shougo/dpp-ext-toml";
import {
  BaseConfig,
  type ConfigReturn,
  type MultipleHook,
} from "jsr:@shougo/dpp-vim/config";
import type { Dpp } from "jsr:@shougo/dpp-vim/dpp";
import type { Protocol } from "jsr:@shougo/dpp-vim/protocol";
import type {
  ContextBuilder,
  ExtOptions,
  Plugin,
} from "jsr:@shougo/dpp-vim/types";
import { mergeFtplugins } from "jsr:@shougo/dpp-vim/utils";
import { expandGlob } from "jsr:@std/fs/expand-glob";
import * as path from "jsr:@std/path";

export class Config extends BaseConfig {
  override async config(args: {
    denops: Denops;
    contextBuilder: ContextBuilder;
    basePath: string;
    dpp: Dpp;
  }): Promise<ConfigReturn> {
    args.contextBuilder.setGlobal({
      extParams: {
        installer: {
          checkDiff: true,
          logFilePath: "~/.cache/dpp/installer-log.txt",
          // githubAPIToken: Deno.env.get("GITHUB_API_TOKEN"),
        },
      },
      protocols: ["git"],
    });
    const [context, options] = await args.contextBuilder.get(args.denops);
    const protocols = (await args.denops.dispatcher.getProtocols()) as Record<
      string,
      Protocol
    >;

    type LazyMakeStateResult = {
      plugins: Plugin[];
      stateLines: string[];
    };

    const dirname = path.resolve(
      path.dirname(path.fromFileUrl(import.meta.url)),
    );

    const tomlsDir = `${dirname}/toml/`;

    const [tomlExt, tomlOptions, tomlParams]: [
      TomlExt,
      ExtOptions,
      TomlParams,
    ] = (await args.denops.dispatcher.getExt("toml")) as [
      TomlExt,
      ExtOptions,
      TomlParams,
    ];

    const action = tomlExt.actions.load;

    const tomlPromises = [
      { path: `${tomlsDir}plugin.toml`, lazy: false },
      ...Array.from(Deno.readDirSync(`${tomlsDir}lazy/`))
        .filter((tomlFile) => tomlFile.name.endsWith(".toml"))
        .map((tomlFile) => ({
          path: `${tomlsDir}lazy/${tomlFile.name}`,
          lazy: true,
        })),
    ].map((tomlFile) =>
      action.callback({
        denops: args.denops,
        context,
        options,
        protocols,
        extOptions: tomlOptions,
        extParams: tomlParams,
        actionParams: {
          path: tomlFile.path,
          options: {
            lazy: tomlFile.lazy,
          },
        },
      }),
    );

    const tomls = await Promise.all(tomlPromises);

    const recordPlugins: Record<string, Plugin> = {};
    const ftplugins: Record<string, string> = {};
    const hooksFiles: string[] = [];
    let multipleHooks: MultipleHook[] = [];

    for (const toml of tomls) {
      for (const plugin of toml.plugins ?? []) {
        recordPlugins[plugin.name] = plugin;
      }

      if (toml.ftplugins) {
        mergeFtplugins(ftplugins, toml.ftplugins);
      }

      if (toml.multiple_hooks) {
        multipleHooks = multipleHooks.concat(toml.multiple_hooks);
      }

      if (toml.hooks_file) {
        hooksFiles.push(toml.hooks_file);
      }
    }

    const [lazyExt, lazyOptions, lazyParams]: [
      LazyExt | undefined,
      ExtOptions,
      LazyParams,
    ] = (await args.denops.dispatcher.getExt("lazy")) as [
      LazyExt | undefined,
      ExtOptions,
      PackspecParams,
    ];
    let lazyResult: LazyMakeStateResult | undefined = undefined;
    if (lazyExt) {
      const action = lazyExt.actions.makeState;

      lazyResult = await action.callback({
        denops: args.denops,
        context,
        options,
        protocols,
        extOptions: lazyOptions,
        extParams: lazyParams,
        actionParams: {
          plugins: Object.values(recordPlugins),
        },
      });
    }

    const checkFiles = [];
    for await (const file of expandGlob(`${Deno.env.get("BASE_DIR")}/*`)) {
      checkFiles.push(file.path);
    }

    return {
      checkFiles,
      ftplugins,
      hooksFiles,
      multipleHooks,
      plugins: lazyResult?.plugins ?? [],
      stateLines: lazyResult?.stateLines ?? [],
    };
  }
}
