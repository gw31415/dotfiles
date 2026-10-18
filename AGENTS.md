# AGENTS.md

## 設定ファイルの置き場所

- `config.toml`: macOS と OCI の両方で使うもの。
- `config.macos.toml`: Mac でしか動かない・使わないもの (GUI、Homebrew/cask/mas、CoreAudio、zsh、TeX、tunnel-client 等)。
- `config.oci.toml`: OCI サーバーでだけ必要なもの。サーバーの system service (dev-session-mcp、cloudflared、/usr/local/bin/tunnel-client) はこの repo の管理外。
- arm64 Linux 向けの配布が無いだけのツールは `config.toml` に置き、`os = ["macos", "linux/x64"]` で絞る。
- module 内の項目には `os = "macos"` を付けない (module の選択で既に絞られている)。
- マシンごとの選択は git 管理外の `miserc.local.toml` (`env = ["macos"]` / `env = ["oci"]`)。コミットしない。
- lockfile は config ファイルごと: `config.toml` → `mise.lock`、`config.<env>.toml` → `mise.<env>.lock`。ツールを module 間で移したら lock の entry も移す。

## mise ツール追加時のバックエンド選定

対象: 上記いずれかの config ファイルにある `[tools]`。

優先順位:

1. デフォルトレジストリ (`mise registry` にあるもの。`node`・`go` 等の素名)
2. エコシステム系バックエンド (`npm:`・`go:`・`cargo:`・`gem:`・`pipx:`・`aqua:` 等)
   - `cargo:` は `cargo.binstall_only = true` のため binstall 提供が必須。提供なしは不可
   - `aqua:` はレジストリ登録があるもののみ (`mise ls-remote aqua:owner/repo` で確認)
3. `ubi:` は非推奨のため使わない。`github:` を使う
4. 最終手段: `github:` バックエンド。同一リリースに複数バイナリ同梱の場合は `tool_alias` + `matching` で分割する(例: emmylua_* + luafmt)

```toml
[tool_alias]
emmylua_ls = "github:EmmyLuaLs/emmylua-analyzer-rust"

[tools.emmylua_ls]
version = "latest"
matching = "emmylua_ls"
```

## mise config 編集時の注意

- `[tools.<name>]` 形式のテーブルは `[tools]` 内のフラットなエントリより後(`[env]` の直前等)に置く。途中挿入すると後続のフラットエントリがそのサブテーブルに吸収される
- 検証: `python3 -c "import tomllib; [tomllib.load(open(f,'rb')) for f in ('config.toml','config.macos.toml','config.oci.toml')]"`、`mise config ls` (読み込まれた module の確認)、`mise install` + `mise which <tool>`
- module ごとの差分確認: `mise -E macos bootstrap --dry-run` / `mise -E oci bootstrap --dry-run`
