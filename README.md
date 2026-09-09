# dotfiles and configurations for ama

mise-first な dotfiles。開発ツール・ランタイム・シェル設定は mise が正で、
Nix は「はみ出る部分」の薄い wrapper のみに縮小している。

| 層              | Linux                              | macOS                              |
| --------------- | ---------------------------------- | ---------------------------------- |
| ツール/言語     | mise (`config.toml`)               | 同左                               |
| dotfiles 配置   | `mise bootstrap dotfiles`           | 同左                               |
| fish plugin     | pez (`config/fish/pez.toml` + lock) | 同左                              |
| 共有ツール層    | 任意: Nix `.#shared` (`nix/shared.nix`) | — (brew が担当)                |
| GUI / host package | —                               | `[bootstrap.packages]`             |
| Nix             | 共有ツール層のみ                   | システム設定・フォント・常駐のみ   |

conda backend の使用は `conda:poppler` / `conda:librsvg` の2点のみ
(prebuilt 配布が conda-forge にしか無いため)。

## Installation

```bash
# 1. mise (公式インストーラ)
curl https://mise.run | sh

# 2. この repository を mise のグローバル構成として採用して bootstrap
#    (mise が ~/.config/mise へ clone・trust してから宣言状態を適用する)
mise bootstrap --adopt <this-repo-url>
```

`mise bootstrap` は以下を宣言的に適用する:

- `config.toml` の `[dotfiles]` に定義した symlink と fish の leaf symlink
- macOS の Homebrew formula / cask と Mac App Store application
  (`[bootstrap.packages]`)
- `[tools]` の mise-managed toolchain
- tools 導入後の `pez install` と `pez doctor`

初回 `mise install` は言語ランタイム (node / go / python / rust / dotnet 等) を
取得するため時間がかかる。

Nix の `.#shared` は任意の互換層であり、bootstrap では導入しない。必要な Linux
環境だけで `nix profile install ~/.config/mise#shared` を明示的に実行する。

Arto は third-party tap の cask で、現在の mise package backend が安全に評価できない。
これは bootstrap の外で、必要な Mac だけに `brew install --cask arto-app/tap/arto` を
明示的に実行する。

### 旧 Home Manager 環境からの移行

mise は既存ファイルを上書きしない。まず `mise bootstrap --dry-run` で対象を
確認し、競合した destination が旧 `/nix/store` symlink であることを確認してから、
その symlink だけを手動で外して再実行する。通常ファイルや出所不明の symlink に
`--force-dotfiles` を使わないこと。

旧構成の `~/.config/mise -> <repo>/config/mise` は互換 symlink により、そのまま
リポジトリ root を指す。既存 checkout を使い続ける場合は adopt し直さず、
`mise trust ~/.config/mise/config.toml` の後に `mise bootstrap` を実行する。
新しいマシンだけ `mise bootstrap --adopt` を使う。

新しい fish を開いた後も、従来どおり `dot`、`dot -h`、`dot -d`、`dot -a`、
`dot -u`、`dot sh`、`dot gc` を使える。内部では user-level apply と開発 shell を
mise に、システム適用・flake 更新・GC を Nix に委譲する。

## `dot` Usage

`dot` のインターフェースは維持する。引数なしと `dot -h` は user-level 設定を
適用し、`dot -d` は macOS の nix-darwin、`dot -a` は両方を適用する。
`dot -u` は従来どおり `flake.lock` だけを更新・コミットし、`dot -ua` はその後に
両方を適用する。mise / pez / Homebrew の更新は `mise run update` を使う。

```bash
dot                 # user-level apply
dot --home          # 同上
dot --darwin        # macOS system apply
dot --all           # user-level + macOS system apply
dot --update        # flake.lock のみ更新・コミット
dot -ua             # lockfile 更新後に両方を apply
dot sh <cmd>        # dotfiles ディレクトリで mise 管理環境を使い <cmd> を実行
dot gc              # Nix garbage collection
dot gc --aggressive # 全世代を削除してから Nix garbage collection
```

### macOS (nix-darwin) の切替・更新

```bash
sudo darwin-rebuild switch --flake ~/dotfiles
```

`flake.lock` 更新後は Mac 側で `nix flake update` すること。

## mise Usage

```bash
mise bootstrap --dry-run          # 変更予定を確認
mise bootstrap                    # dotfiles・host package・tools を収束
mise bootstrap dotfiles apply     # dotfiles だけを収束
mise bootstrap packages status    # host package の状態確認
mise run update                   # package / mise tool / pez の更新
```

## fish plugins (pez)

`config/fish/pez.toml` が一覧、`config/fish/pez-lock.toml` が固定版。
追加・更新は `pez` コマンドで行い、lock をコミットすること。
- `~/.config/fish/{functions,completions,conf.d}` は実ディレクトリのまま、
  repo ファイルを1件ずつ symlink する (pez が plugin をコピーする先のため)。
