# dotfiles and configurations for ama

mise-first な dotfiles。開発ツール・ランタイム・シェル設定は mise が正で、
Nix は「はみ出る部分」の薄い wrapper のみに縮小している。

## 構成

共通設定と、マシンごとに選ぶ module (mise の config environment) に分けている。

| ファイル            | 読み込むマシン | 中身                                                                 |
| ------------------- | -------------- | -------------------------------------------------------------------- |
| `config.toml`       | 全マシン       | ランタイム・シェル・LSP・開発/日常 CLI、nvim/fish/git などの dotfiles |
| `config.macos.toml` | Mac            | brew / cask / mas、zsh・TeX・ghostty・audiorouter、tunnel-client 等   |
| `config.oci.toml`   | OCI サーバー   | OCI 専用の追加分 (現状なし)。サーバー常駐はこの repo の管理外と明記   |
| `miserc.local.toml` | (git 管理外)   | そのマシンで読む module の選択                                        |
| `mise.lock` / `mise.<env>.lock` | —  | 各 config ファイルに対応する lockfile                                 |
| `flake.nix`, `nix/` | Mac (+任意で Linux) | nix-darwin のシステム設定・フォント・LaunchAgent、Linux の任意共有層 |

| 層                 | OCI (Linux)                          | macOS                                  |
| ------------------ | ------------------------------------ | -------------------------------------- |
| ツール/言語        | mise (`config.toml`)                 | mise (`config.toml` + `config.macos.toml`) |
| dotfiles 配置      | `mise bootstrap` (`[dotfiles]`)      | 同左                                   |
| fish plugin        | pez (`config/fish/pez.toml` + lock)  | 同左                                   |
| ログインシェル     | bash (fish は対話・herdr で使う)     | fish (`/opt/homebrew/bin/fish`)          |
| GUI / host package | —                                    | `[bootstrap.packages]` (macOS module)   |
| 常駐サービス       | system service (repo 管理外)         | nix-darwin の LaunchAgent              |
| Nix                | 未使用 (任意: `.#shared`)            | システム設定・フォント・常駐のみ       |

conda backend の使用は `conda:poppler` / `conda:librsvg` の2点のみ
(prebuilt 配布が conda-forge にしか無いため)。

### どこに書くか

- 両方のマシンで使うもの → `config.toml`
- Mac でしか動かない・使わないもの (GUI、CoreAudio、Homebrew、zsh、TeX) → `config.macos.toml`
- OCI サーバーでだけ必要なもの → `config.oci.toml`
- arm64 Linux 向けの配布が無いだけのツールは `config.toml` に置き、
  `os = ["macos", "linux/x64"]` で絞る。

## Installation

```bash
# 1. mise (公式インストーラ)。module の選択に 2026.10.13 以降が必要。
curl https://mise.run | sh

# 2. この repository を mise のグローバル構成として採用する
#    (mise が ~/.config/mise へ clone・trust し、共通設定だけで一度収束させる)
mise bootstrap --adopt <this-repo-url>

# 3. このマシンの module を選んで、もう一度 bootstrap する
echo 'env = ["macos"]' > ~/.config/mise/miserc.local.toml   # Mac
echo 'env = ["oci"]'   > ~/.config/mise/miserc.local.toml   # OCI サーバー
mise bootstrap --dry-run
mise bootstrap
```

Mac では bootstrap 後に Homebrew の fish をログインシェルにする (初回のみ):

```bash
echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish
```

`mise bootstrap` は以下を宣言的に適用する:

- 選択した module を含む `[dotfiles]` の symlink と fish の leaf symlink
- macOS の Homebrew formula / cask と Mac App Store application
  (`[bootstrap.packages]`、macOS module のみ)
- `[tools]` の mise-managed toolchain
- tools 導入後の `pez install` と `pez doctor`

初回 `mise install` は言語ランタイム (node / go / python / rust / dotnet 等) を
取得するため時間がかかる。

Nix の `.#shared` は任意の互換層であり、bootstrap では導入しない。必要な Linux
環境だけで `nix profile install ~/.config/mise#shared` を明示的に実行する。

### module を外す・切り替える

`miserc.local.toml` から外しただけでは、その module が置いた symlink は残る。
外す前に `mise bootstrap unapply <module> --dry-run` で確認してから削除する。
module 由来の mise ツールは `mise prune` で消えるので、残したいものがあれば先に確認する。

### herdr

herdr は実行時ファイル (socket・log・session) を `~/.config/herdr` に置くため、ディレクトリごとの
symlink をやめ、`config.toml` だけを `files/herdr-config.toml` から template として描画する。
`default_shell` は `~` や環境変数を展開せず、herdr サーバーの PATH に mise の shim が
入らないことがあるため、fish は OS ごとの絶対パスを埋め込む。設定の変更は template を編集して
`mise bootstrap dotfiles apply` と `herdr server reload-config` を実行する。

旧構成 (`~/.config/herdr -> ~/.config/mise/config/herdr`) から移行するマシンでは、一度だけ次を実行する
(同じファイルシステム内の移動なので、起動中の herdr の socket はそのまま使える):

```bash
rm ~/.config/herdr && mv ~/.config/mise/config/herdr ~/.config/herdr
rm ~/.config/herdr/config.toml ~/.config/herdr/.gitignore
mise bootstrap dotfiles apply && herdr server reload-config
```

### 旧 Home Manager 環境からの移行

mise は既存ファイルを上書きしない。まず `mise bootstrap --dry-run` で対象を
確認し、競合した destination が旧 `/nix/store` symlink であることを確認してから、
その symlink だけを手動で外して再実行する。通常ファイルや出所不明の symlink に
`--force-dotfiles` を使わないこと。

旧構成の `~/.config/mise -> <repo>/config/mise` は互換 symlink (`config/mise -> ..`)
により、そのままリポジトリ root を指す。既存 checkout を使い続ける場合は adopt し直さず、
`mise trust ~/.config/mise/config.toml` の後に `mise bootstrap` を実行する。
新しいマシンだけ `mise bootstrap --adopt` を使う。

## `dot` Usage

`dot` のインターフェースは維持する。引数なしと `dot -h` は user-level 設定を
適用し、`dot -d` は macOS の nix-darwin、`dot -a` は両方を適用する。
`dot -u` は `flake.lock` だけを更新・コミットし、`dot -ua` はその後に
両方を適用する。mise / pez / Homebrew の更新は `mise run update` を使う。

```bash
dot                 # user-level apply (mise bootstrap)
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
dot -d
# 直接実行する場合
sudo darwin-rebuild switch --flake ~/.config/mise
```

## mise Usage

```bash
mise bootstrap --dry-run          # 変更予定を確認
mise bootstrap                    # dotfiles・host package・tools を収束
mise bootstrap dotfiles apply     # dotfiles だけを収束
mise bootstrap packages status    # host package の状態確認 (Mac)
mise config ls                    # 読み込まれている config (module) を確認
mise run update                   # package / mise tool / pez の更新
```

## fish plugins (pez)

`config/fish/pez.toml` が一覧、`config/fish/pez-lock.toml` が固定版。
追加・更新は `pez` コマンドで行い、lock をコミットすること。
- `~/.config/fish/{functions,completions,conf.d}` は実ディレクトリのまま、
  repo ファイルを1件ずつ symlink する (pez が plugin をコピーする先のため)。
