# dotfiles and configurations for ama

mise-first な dotfiles。開発ツール・ランタイム・シェル設定は mise が正で、
Nix は「はみ出る部分」の薄い wrapper のみに縮小している。

| 層              | Linux                              | macOS                              |
| --------------- | ---------------------------------- | ---------------------------------- |
| ツール/言語     | mise (`config/mise/config.toml`)   | 同左                               |
| dotfiles 配置   | `mise run link`                    | 同左                               |
| fish plugin     | pez (`config/fish/pez.toml` + lock) | 同左                              |
| 共有ツール層    | 任意: Nix `.#shared` (`nix/shared.nix`) | — (brew が担当)                |
| GUI / brew 基盤 | —                                  | `Brewfile` (`mise run bootstrap`)  |
| Nix             | 共有ツール層のみ                   | システム設定・フォント・常駐のみ   |

conda backend の使用は `conda:poppler` / `conda:librsvg` の2点のみ
(prebuilt 配布が conda-forge にしか無いため)。

## Installation

```bash
# 1. mise (公式インストーラ)
curl https://mise.run | sh

# 2. clone
git clone <this-repo> ~/dotfiles && cd ~/dotfiles

# 3. symlink 配置 (mise 不要で直接実行できる)
./config/mise/tasks/link.sh

# 4. このリポジトリを信頼 (初回のみ)
mise trust ~/dotfiles

# 5. bootstrap
mise run bootstrap
```

`mise run bootstrap` は OS 別に以下を行う:

- Linux: `mise install` → `pez install` + `pez doctor` → fish をログインシェルに
  (`chsh`)。Nix が導入済みなら、Nix 専用 formatter・ネイティブ依存の任意層も
  `nix profile install .#shared` で導入する
- macOS: Homebrew 導入 (未導入時) → `brew bundle --file Brewfile` →
  同上 (`mise install`, `pez`, `chsh`)
  - Nix が未導入なら https://nixos.org/download から導入後、
    `sudo darwin-rebuild switch --flake ~/dotfiles`

初回 `mise install` は言語ランタイム (node / go / python / rust / dotnet 等) を
取得するため時間がかかる。

### 旧 Home Manager 環境からの移行

旧 Nix profile の `dot` を、mise-first 実装へ差し替えるため、最初の一回だけ clone 済みリポジトリから直接
`./config/mise/tasks/link.sh` を実行する。この処理は、現在このリポジトリが
管理する destination の Nix store symlink だけを置き換え、通常ファイルや
それ以外の symlink は停止して手動解決を求める。

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

tap trust (Homebrew 6.0) で `brew bundle` が失敗したら、
`brew tap <tap>` を手動実行して再試行すること。

## `mise run` Usage

```bash
mise run link      # config/*, files/* を $HOME へ symlink (冪等)
mise run bootstrap # 初期構築 (link 含む)
mise run update    # mise / pez / brew・Nix 層の更新
```

## fish plugins (pez)

`config/fish/pez.toml` が一覧、`config/fish/pez-lock.toml` が固定版。
追加・更新は `pez` コマンドで行い、lock をコミットすること。
- `~/.config/fish/{functions,completions,conf.d}` は実ディレクトリのまま、
  repo ファイルを1件ずつ symlink する (pez が plugin をコピーする先のため)。
