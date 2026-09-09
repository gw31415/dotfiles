# AGENTS.md

## mise ツール追加時のバックエンド選定

対象: repository root の `config.toml` にある `[tools]`。

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
- 検証: `python3 -c "import tomllib; tomllib.load(open('config.toml','rb'))"` と `mise install` + `mise which <tool>`
