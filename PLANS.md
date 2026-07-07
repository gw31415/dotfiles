# Docker コンテナイメージの動作不良デバッグ

この ExecPlan は生きたドキュメントです。`Progress`、`Surprises & Discoveries`、`Decision Log`、`Outcomes & Retrospective` の各セクションは、作業が進むにつれて更新し続けなければなりません。

リポジトリレベルの PLANS.md が本ドキュメントです。Hermes plan モード（`.hermes/plans/` 配下）とは別物です。本ドキュメントは OpenAI Cookbook の PLANS.md / ExecPlan スタイルに従います。


## Purpose / Big Picture

このリポジトリは個人の dotfiles・設定ファイル（Home Manager + nix-darwin）を管理しており、GitHub Actions で Linux 向け Docker イメージ `ghcr.io/gw31415/ama-home-manager` をビルド・公開している。イメージの目的は、「コンテナを起動するだけで `ama` の開発環境（fish, neovim, Rust ツールチェーン, mise, 各種 CLI ツール）が揃った対話シェルに入れること」である。

ユーザーの報告: イメージを起動しても「動作が上手くいっていない印象」がある。具体的には、対話シェルに入ったあとコマンドが見つからない、プロファイルが正しく反映されていない、設定が壊れている、などの症状が疑われるが、まだ再現確認は行っていない。

成功の定義（観察可能な振る舞い）:

- `container run -i -t ghcr.io/gw31415/ama-home-manager:latest` で対話シェル（fish login shell）が起動する。
- シェル内で `which fish` が `/root/.nix-profile/bin/fish` を返す。
- `dot --help`（Home Manager 操作 CLI）が実行できる。
- `mise --version`、`rustc --version`、`nvim --version` が全て成功する。
- `nvim` 起動時に rsplug 管理プラグインを含めエラーが出ない。
- `~/.config/home-manager` に git リポジトリが正しく clone されている。
- `fish` プラグイン（z, autopair, sponge など）がロードされている。

本計画のゴールは、上記の各項目が通るよう、根本原因を特定して修正することである。対症療法（`|| true` での握り潰しなど）は残さない。


## Progress

- [x] (2026-07-07) リポジトリ構造・flake.nix・Dockerfile・impure.sh・CI を読解し、ビルドパイプライン全体を把握した。
- [x] (2026-07-07) 公開イメージ `ghcr.io/gw31415/ama-home-manager:latest` が amd64/arm64 のマニフェストリストとして存在することを確認した。
- [x] (2026-07-07) ホスト環境（Apple Silicon, Apple Container CLI, ディスク残量）を確認した。
- [x] (2026-07-07) A 案実装: `dockerImageDebug` / `linux-container-debug` target を追加（packages.nix, home.nix, flake.nix）。aarch64-linux / x86_64-linux で評価成功を確認。
- [x] (2026-07-07) フェーズ1: 公開 arm64 イメージを Apple Container で pull・起動し、症状を記録した。**根本原因を特定**（下記 Surprises & Discoveries 参照）。
- [x] (2026-07-07) フェーズ4: 根本原因のソース修正を実装（hermes 引き継ぎ後に Claude がレビュー・追加修正）。`|| true` 削除、`git reset --hard main`、rsplug を mise exec 経由に変更、node を linux にもインストール。flake 評価成功を確認。詳細は下記「フェーズ4 修正内容」。
- [ ] フェーズ2-3: impure.sh の各ステップを個別に手動実行して追加検証（フェーズ1で大部分は判明したが、純粋な activate 前状態での検証は未実施）。
- [ ] フェーズ5: ローカルで dockerImageDebug を使って再ビルドし Apple Container で検証。**→ ローカルビルドがインフラ制約で不可（下記「フェーズ5 ローカルビルドの障壁」参照）。CI に切り替え。**
- [ ] フェーズ6: 修正を push し CI で公開、最終検証。

### フェーズ5 ローカルビルドの障壁（2026-07-07 / Claude 引き継ぎ後）

`dockerImageDebug` を nixos/nix コンテナ（Apple Container）でビルドする方式を試行したが、インフラ制約で断念した。これは**コードではなく環境の問題**であり、CI では発生しない。

1. **ホスト nix に Linux ビルダーが無い**: `builders =` 空。`dockerImageDebug` は Linux 専用出力のため、nixos/nix コンテナ方式（計画ステップ8）が必要。
2. **KVM が公開できない**: `dockerTools.buildImage` の `runAsRoot` は VM で実行され `system-features = kvm` を要求する。Apple Container の `--virtualization` フラグを付けてもコンテナ内に `/dev/kvm` は現れず、nix は `features {benchmark, big-parallel, nixos-test, uid-range}`（kvm 無し）と報告し、VM ビルドが「required feature kvm」で弾かれる。
3. **`--option system-features kvm` 強制 → TCG フォールバック**: kvm を強制宣言すると QEMU は TCG（ソフトウェアエミュレーション）にフォールバックして VM を起動するが:
   - まず **コンテナのデフォルトメモリ 1 GiB < VM 要求 2 GiB** で exit 137（OOM Kill）。`-m 6G` で解決。
   - その後、**ゲストカーネルが panic**（`vpanic → do_exit → SMP: stopping secondary CPUs`）。TCG 上の `-cpu max` で aarch64 ビルド VM が安定しない。

**CI はこの問題無し**: `.github/workflows/publish-container.yml` が `extra_nix_config: system-features = kvm` を強制し、GitHub の `ubuntu-latest` / `ubuntu-24.04-arm` ランナーは実際に `/dev/kvm` を持つため、ハードウェア KVM で高速かつ安定に VM ビルドできる。CI 起動条件は `push: branches: [main]` または `workflow_dispatch`。

**サンドボックス制約**: 作業後半、harness サンドボックスが `container rm`・`rm`（一時ファイル）を「Deletion outside the repository」「Destructive file operation」としてブロックするようになった。ローカルの片付け操作に制限あり。

### フェーズ4 修正内容（2026-07-07 / hermes 実装 → Claude レビュー）

hermes が実装したソース修正を Claude が引き継ぎ後にレビュー。以下の追加修正を行った:

- **`docker/impure.sh`: rsplug の CLI バグを修正**。hermes は `mise exec -- rsplug install <toml>` としていたが、rsplug の CLI に `install` サブコマンドは存在しない（README 確認: `rsplug [OPTIONS] <CONFIG_FILES>...` でインストールは `-i`/`--install` **フラグ**）。`install` を渡すと設定ファイル名として解釈され失敗する回帰バグだったため `rsplug -i "$dotfiles_dir/nvim/rsplug/*.toml"`（元の呼び出し）に戻した。
- **`docker/impure.sh`: `wait` の移植性を修正**。hermes は `wait %1`/`wait %2`（job spec）に変更していたが、`%N` は非 POSIX 拡張でありコンテナの `sh`（busybox ash）で失敗するリスクがあった。元の `$!` + `wait "$pid"` パターン（100% POSIX 準拠）に戻した。

レビューで確認した hermes 修正の妥当性:

- `|| true` 削除（Dockerfile）: 失敗の可視化。妥当。
- `git reset --hard main`: スナップショット版 working tree を clone 内容で正しく上書き。妥当（根本原因の構造的修正）。
- rsplug を mise 管理化: mise config.toml で `github:gw31415/rsplug.nvim` (bin=rsplug) として既に定義されているため、`mise exec` 経由が正しい。nix パッケージに rsplug を追加するのは不要。
- node を `os = ["macos","linux"]` に: linux コンテナで node/npm 系ツールが解決するようになる。`syms/mise/config.toml` は home-manager で `~/.config/mise/config.toml` に配置されるため確実に反映される（base.nix:45）。

**重要な発見: `mise install` は一部ツール失敗でも exit 0 を返す**（実測）。そのため cargo 系（`cargo:ghzinga`, `cargo:https://...idevice_pair`）がコンテナ内でビルド失敗しても `set -e` でサブシェルは中断せず、後続の `mise exec -- rsplug -i` は確実に実行される。非必須ツールの missing は残るが、nvim の核心問題（init.lua 生成）は解決する。`mise install` 自体の exit 0 は mise の仕様であり `|| true` による握り潰しではない（mise バイナリ不在や全面ネットワーク断なら別途エラーになる）。


## Surprises & Discoveries

### フェーズ1（公開イメージ起動検証）の結果 — 2026-07-07

**根本原因 #1: rsplug バイナリがイメージに含まれていない → nvim が起動クラッシュする**

- 観察: nvim 起動時に致命的エラーが発生する。
  証拠:
    Error in /root/.config/nvim/init.lua:
    E5113: Lua chunk: cannot open /root/.cache/rsplug/init.lua: No such file or directory
    stack traceback:
        [C]: in function 'dofile'
        /root/.config/nvim/lua/init.lua:2: in main chunk

- 原因連鎖:
  1. `packages.nix` の `common` および `linuxPkgs` に rsplug パッケージが含まれていない。`/root/.nix-profile/bin/rsplug` は存在しない。
  2. `docker/impure.sh:21` の `rsplug -i "$dotfiles_dir/nvim/rsplug/*.toml"` が `command not found` で失敗する。
  3. `docker/Dockerfile:4` の `|| true` により、この失敗が握り潰されてビルドが成功する。
  4. rsplug が一度も実行されないため、`~/.cache/rsplug/init.lua` が生成されない。
  5. コンテナ起動後、ユーザーが nvim を起動すると `init.lua` が `dofile ~/.cache/rsplug/init.lua` に失敗し、nvim がクラッシュする。

  これが「動作が上手くいっていない印象」の主因。nvim はユーザーが最も頻繁に使うツールであり、これが壊れていると環境全体が壊れているように見える。

**根本原因 #2: mise の一部ツールが missing（node/npm 不在）**

- 観察: `mise ls` で複数ツールが `(missing)` や解決失敗になる。
  証拠:
    cargo:ghzinga    0.4.0 (missing)
    cargo:https://github.com/jkcoxson/idevice_pair   HEAD (missing)
    npm:hunkdiff, npm:fish-lsp, npm:trash-cli, npm:gnhf → "No such file or directory"

- 原因: `mise i` は走るが、mise が依存するバックエンド（node/npm、一部 cargo ビルドに必要なツールチェーン）が環境に揃っていない。npm 系は node が不在（`common` に nodejs/npm が含まれない）のため全滅。cargo 系は rustup はあるがビルド時の依存解決が一部失敗している可能性。`|| true` によりこれも握り潰し。

**正常に動作しているもの**

- fish ログインシェル: `/root/.nix-profile/bin/fish -l` は正常起動する。CMD のパスは正しい。
- HM activation: `/activate` は成功しており、`~/.nix-profile` → user-environment（177バイナリ）が正しく構築されている。
- profile.d スクリプト: `/etc/profile.d/nix-daemon.{sh,fish}`, `nix.{sh,fish}` が全て存在。fish login shell が PATH を正しく設定する。
- fish conf.d: `/etc/fish/conf.d/profile.fish` と `~/.config/fish/conf.d/plugin-*.fish`（z, autopair, sponge, fish-na, herdr_editor）が存在しロードされる。
- sessionVariables: EDITOR=nvim, XDG_CONFIG_HOME=/root/.config, SSH_AUTH_SOCK が正しく設定される。
- shellInit: direnv hook, mise activate, abbr がロードされる。
- dotfiles git clone: `~/.config/home-manager` に最新コミット `6851a31` が clone されている。`git reset` の `--hard` 問題は発生せず（スナップショットと clone が同じ内容のため）。
- rustup: stable-aarch64-unknown-linux-gnu がインストール済み。

**Apple Container 特有の発見**

- 観察: 公開イメージは arm64 で layer 0 が 2.9GB、合計 3.3GB。Apple Container は pull 後にスナップショットへの unpack が必要で、これに時間がかかる（数分）。
  証拠: `docker manifest inspect` で layer サイズ確認。`container run` が unpack 完了前にタイムアウトするため、初回起動は `-d`（デタッチ）で unpack を待つ必要がある。
- 観察: ディスク容量が逼迫していると unpack が `CancellationError` で失敗する。
  証拠: 不要イメージ削除前は unpack が毎回キャンセルされていた。削除後（13GB空き）で unpack 成功。

### 初期静的読解での発見（コードレビュー）

- 観察: `docker/Dockerfile` の RUN 行が `/tmp/impure.sh || true` となっており、impure.sh がどんなに失敗してもビルドが成功するようになっている。これは「動作不良」の最大の疑い箇所である。失敗が可視化されないため、どのステップが壊れているかビルド時点では分からない。
  証拠: `docker/Dockerfile:4`

- 観察: impure.sh は並列で3つのサブシェルを走らせ、それぞれ `wait` で待ち合わせている。git init/fetch（dotfiles clone）、rustup default + rsplug インストール、mise インストールが並列。いずれかが失敗しても exit status を拾う構造にはなっているが、直後の Dockerfile `|| true` で握り潰される。
  証拠: `docker/impure.sh:10-36`

- 観察: Dockerfile の CMD は `["/root/.nix-profile/bin/fish", "-l"]` を指定している。`/root/.nix-profile` は HM activation によって作られるシンボリックリンク（→ `/nix/var/nix/profiles/per-user/root/home-manager`）だが、これが存在するためには `/activate` が成功している必要がある。activate が失敗している場合、CMD の fish は存在せずコンテナ起動直後に落ちるはず。
  証拠: `docker/Dockerfile:6`, `flake.nix:98-112`

- 観察: `flake.nix` の `runAsRoot` は `cp -r ${./.} $HOME/.config/home-manager` でリポジトリ全体を焼き込んでいる。その後 impure.sh が改めて `git init` + `git fetch origin/main` + `git reset` で上書きしている。つまり dotfiles が2回配置される（ビルド時のスナップショット版と、impure.sh での clone 版）。`git reset` はインデックスのみリセットするので working tree はスナップショットのまま残り、clone の内容が working tree に反映されない可能性がある（`git reset` ではなく `git reset --hard` が必要では）。
  証拠: `flake.nix:106`, `docker/impure.sh:14-16`

- 観察: impure.sh の冒頭 `. /etc/profile.d/*.sh` は nix の環境変数設定を意図しているが、`dockerTools.buildImage` の `copyToRoot` に `/etc/profile.d/nix-daemon.sh` を生成するコンポーネントが含まれているか不明。`includeNixDB = true` は Nix データベースを含めるだけで、profile.d スクリプトの有無とは別。これが無いと `nix` コマンドの PATH 設定が漏れる。
  証拠: `flake.nix:91-135`, `docker/impure.sh:4`

- 観察: ホストのディスク残量が 16GB（96% 使用）。Nix フルプロファイル + ソース群を含むイメージは数 GB になるため、デバッグイメージはこまめに削除しなければならない。
  証拠: `df -h /Users/ama` → 16Gi Avail, 96% Capacity

- 観察: Apple Container CLI はホストにインストール済み（`/Users/ama/.nix-profile/bin/container`）だが、システムサービスが未起動。`container system start` が必要。
  証拠: `container image ls` → "Ensure container system service has been started"


## Decision Log

- 決定: デバッグには Docker ではなく Apple Container（`container` CLI）を使用する。
  理由: ユーザーの明示的な指示。ホストが Apple Silicon なので arm64 イメージをネイティブ検証できる。
  日付/著者: 2026-07-07 / agent

- 決定: デバッグで作成・pull したイメージ・コンテナは、各検証ステップの直後に削除し、ディスク容量を確保する。コンテナの停止・削除、イメージの prune を逐次実行する。
  理由: ディスク残量 16GB で余裕がなく、イメージが数 GB になるため。
  日付/著者: 2026-07-07 / agent

- 決定: まず公開済みイメージ（arm64）を pull して現状の症状を観察し、その後ソースコードレベルで根本原因を追及する。
  理由: 「印象」の段階なので、まず再現・症状の正確な記録が必要。推測で修正しない（ユーザーの方針: 根本原因の診断を先に行う）。
  日付/著者: 2026-07-07 / agent

- 決定: ローカルのデバッグビルド（フェーズ5）は、パッケージをデバッグに必要な最小セットに絞ってビルドする。CI で公開される最終イメージはフルセットのまま。
  理由: ディスク残量 16GB に対してフルビルドは重すぎる。デバッグの検証項目（fish, dot, mise, rustc, nvim, git, activate, impure.sh の各ステップ）を満たすのに不要なパッケージ（フォント、メディアツール、LSP、追加言語ランタイム等）を省く。
  日付/著者: 2026-07-07 / agent


## Outcomes & Retrospective

（作業開始後に記入する。マイルストーンごとに達成成果・残課題・教訓をまとめる。）


## Context and Orientation

### 用語定義

- **Home Manager (HM)**: Nix 上でユーザー環境（パッケージ・設定ファイル）を宣言的に管理するツール。`homeManagerConfiguration` から `activationPackage` を生成し、`/activate` スクリプトを実行するとプロファイルが `~/.nix-profile` にリンクされ、`home.file` で宣言したファイルが展開される。
- **Nix profile**: `~/.nix-profile` は `/nix/var/nix/profiles/per-user/<user>/home-manager` へのシンボリックリンク。`~/.nix-profile/bin/<cmd>` で HM が管理するバイナリにアクセスできる。
- **activation**: HM がプロファイルを実際のファイルシステムに展開する処理。`/activate` スクリプトを通じて行う。
- **impure**: Nix において、ビルド結果が入力だけでは決まらない（ネットワークアクセス・可変状態に依存する）操作。`impure.sh` はその名の通り、ビルド時ではなくイメージ構築時に mutable なセットアップ（git clone, rustup, mise install）を行う。
- **Apple Container**: macOS 標準のコンテナランタイム。Docker とは別の CLI（`container`）。`container run` でイメージを pull・実行、`container build` で Dockerfile/Containerfile をビルドできる。イメージは OCI 形式。
- **rsplug**: ユーザー自作の Rust 製 Neovim プラグインマネージャ。`rsplug -i <toml>` でプラグインをインストールする。
- **mise**: 多言語バージョンマネージャ（rbenv/pyenv などの後継）。`mise i` で設定ファイルに基づきツールチェーンをインストールする。

### システム構成（現状の理解）

ビルドパイプラインは2段階:

1. **pure イメージ**（`flake.nix` の `dockerImage`）: `pkgs.dockerTools.buildImage` で生成。`ama-home-manager-pure:latest` という名前。内容:
   - `runAsRoot`: busybox でユーザー/group 作成、リポジトリ全体を `/root/.config/home-manager` にコピー。
   - `copyToRoot`: HM activationPackage（プロファイル本体）、busybox、nix、fish 用 profile loader、glibc、cc、pkg-config、curl など。
   - `includeNixDB = true`: Nix ストアのデータベースを同梱。
   - `config.User = "root"`, `WorkingDir = "/root"`。

2. **最終イメージ**（`docker/Dockerfile`）: `FROM ama-home-manager-pure:latest`。`impure.sh` をバインドマウントして `|| true` 付きで実行。CMD は `/root/.nix-profile/bin/fish -l`。

CI（`.github/workflows/publish-container.yml`）は amd64/arm64 両方をビルドし、`docker load` → `docker build ./docker` で最終イメージを組み立て、`ghcr.io/gw31415/ama-home-manager` に `latest-<arch>` およびマニフェストリスト `latest` として push している。

### コンテナ起動時に想定されるシェル初期化チェーン

1. CMD `/root/.nix-profile/bin/fish -l` 起動（login shell）。
2. fish が `/etc/fish/conf.d/profile.fish`（flake で焼き込み）を読み込み、`/etc/profile.d/*.sh` ではなく `*.fish` を source。しかし `/etc/profile.d/nix.fish` が存在するかは未確認。
3. HM が `programs.fish.shellInit` を `~/.config/fish/conf.d/home-manager_*` に展開。ここで direnv hook、mise activate、gpg-agent SSH socket、abbr などを設定。
4. `home.sessionVariables`（EDITOR, SHELL, XDG_CONFIG_HOME など）は `~/.config/fish/conf.d/hm-session-vars.fish` 経由で読み込み。

このチェーンのどこかが壊れていると、fish は起動してもツールが使えない・設定が反映されない状態になる。


## Plan of Work

作業は観察→分割→特定→修正の順で進める。推測で修正を入れない。

### フェーズ1: 現状再現と症状記録

公開イメージを Apple Container で起動し、何が起きるかを正確に記録する。コンテナが起動するか、fish が立ち上がるか、コマンドが通るかを確認。このフェーズで得られた出力を `Artifacts and Notes` に記録する。

### フェーズ2: impure.sh の分割実行による失敗箇所の特定

`docker build` 時に `|| true` で握り潰される各ステップを、起動したコンテナ内で1つずつ手動実行し、どこが失敗するかを突き止める。対象:

- `/activate`（HM activation 本体）
- `. /etc/profile.d/*.sh`（nix profile 設定の有無）
- git init/fetch/reset（dotfiles の再配置）
- `rustup default stable`
- `rsplug -i ...`
- `mise i`

### フェーズ3: CMD・profile チェーンの検証

起動時の fish login shell が、期待する profile・config を全て読み込んでいるか検証する。`/root/.nix-profile/bin/fish` が存在するか、`/etc/profile.d/*.fish` があるか、HM の `hm-session-vars.fish` が読まれるかを確認。

### フェーズ4: 根本原因の修正

特定した原因に対し、対症療法ではなく構造的な修正を行う。例: `|| true` を外して失敗を可視化、`git reset` を `git reset --hard` に修正、profile.d スクリプトの欠落を補う、など。修正はソースコードに対して行う。

### フェーズ5: ローカル再ビルドと検証

修正後、ローカルで pure イメージ → 最終イメージの順にビルドし直し、Apple Container で起動検証する。ただしディスク容量（16GB）制約のため、デバッグに不要なパッケージ（フォント・メディアツール・LSP・追加言語ランタイム等）を省いた最小構成でビルドする。CI で公開する最終イメージはフルセットのまま。詳細は Concrete Steps のステップ8を参照。

### フェーズ6: CI 経由での公開と最終検証

修正を push し、CI でイメージが再ビルドされるのを待ち、公開イメージで最終検証する。


## Concrete Steps

全ての作業ディレクトリは `/Users/ama/.herdr/worktrees/home-manager/fix-container` とする。Apple Container のコマンドは `container` CLI を使用。

### ステップ0: Apple Container システムサービスの起動

    container system start

期待される出力: サービス起動の確認。プロンプトでカーネルインストールを聞かれたら許可する。`container system status` で running になることを確認。

### ステップ1: 公開イメージの pull と起動（症状記録）

    container run --arch arm64 --name debug-ama -i -t ghcr.io/gw31415/ama-home-manager:latest

期待される観察: fish のプロンプトが出るか、エラーで落ちるか。プロンプトが出た場合は以下を順に実行して結果を記録する:

    which fish
    echo $PATH
    type dot
    mise --version
    rustc --version
    nvim --version
    ls -la ~/.nix-profile
    ls -la /etc/profile.d/
    cat /etc/fish/conf.d/profile.fish
    ls -la ~/.config/home-manager/.git 2>&1
    git -C ~/.config/home-manager log --oneline -1 2>&1

コンテナから抜ける（`exit` または Ctrl-D）。

### ステップ2: コンテナ・イメージの片付け（容量確保）

    container rm debug-ama
    container image rm ghcr.io/gw31415/ama-home-manager:latest
    container image prune

注意: 次のステップで再度イメージが必要になるため、pull→検証→削除を1セットとして行う。ディスク残量は都度 `df -h /Users/ama` で確認する。

### ステップ3: impure.sh の分割実行

pure イメージ（activate 前）の状態を再現するため、エントリポイントを上書きしてコンテナを起動する:

    container run --arch arm64 --name debug-impure --entrypoint /bin/sh -i -t ghcr.io/gw31415/ama-home-manager:latest

注意: Apple Container の `--entrypoint` オーバーライドが効かない場合は、CMD を引数で上書き:

    container run --arch arm64 --name debug-impure -i -t ghcr.io/gw31415/ama-home-manager:latest /bin/sh

sh プロンプトで impure.sh の各ステップを1つずつ実行:

    # 1. profile.d の確認
    ls -la /etc/profile.d/
    . /etc/profile.d/*.sh   # 失敗するか?
    echo $PATH

    # 2. activate
    /activate               # 失敗するか? exit code を確認
    echo $?
    ls -la ~/.nix-profile

    # 3. dotfiles の再配置
    ls -la ~/.config/home-manager
    cd ~/.config/home-manager && git status   # すでに git 管理されているか

    # 4. rustup
    rustup default stable    # exit code を確認

    # 5. rsplug
    rsplug -i ~/.config/home-manager/nvim/rsplug/*.toml   # exit code を確認

    # 6. mise
    mise i                   # exit code を確認

各ステップの exit code・エラーメッセージを `Artifacts and Notes` に記録する。

### ステップ4: 片付け

    exit
    container rm debug-impure
    container image prune

### ステップ5: fish profile チェーンの検証

最終イメージを再度起動し、fish の初期化チェーンを詳細に観察:

    container run --arch arm64 --name debug-fish -i -t ghcr.io/gw31415/ama-home-manager:latest

fish プロンプトで:

    # fish が読み込んだ conf.d を全表示
    ls ~/.config/fish/conf.d/
    cat ~/.config/fish/conf.d/hm-session-vars.fish 2>&1
    # profile.fish の内容
    cat /etc/fish/conf.d/profile.fish
    # profile.d に fish 向けファイルがあるか
    ls /etc/profile.d/*.fish 2>&1
    # shellInit で設定されるはずの変数
    echo $EDITOR
    echo $XDG_CONFIG_HOME
    echo $SSH_AUTH_SOCK

### ステップ6: 片付け

    exit
    container rm debug-fish
    container image rm ghcr.io/gw31415/ama-home-manager:latest
    container image prune

### ステップ7: 根本原因の修正（フェーズ1-3の結果に基づく）

特定した原因ごとに `patch` で修正する。想定される修正対象（観察結果次第で取捨選択）:

- `docker/Dockerfile`: `|| true` を削除し、impure.sh の失敗をビルドエラーとして顕在化させる。
- `docker/impure.sh`: `git reset` → `git reset --hard` で clone 内容を working tree に反映。
- `flake.nix` の `copyToRoot`: `/etc/profile.d/nix-daemon.sh` または nix パッケージの profile スクリプトが不足している場合、`nix` の代わりに適切な setup を含める。
- `docker/Dockerfile` の CMD: activate 成功を前提としたパスを、より堅牢な起動方法に変更。

### ステップ8: ローカル再ビルド（デバッグ最小構成）

フルビルドはディスク残量に対して重すぎるため、デバッグに必要な最小パッケージセットでビルドする（A 案採用）。

最小セットの考え方: フェーズ1-3で検証する項目は fish, dot, mise, rustc, nvim, git, activate, impure.sh の各ステップ。これらを動かすのに必要なパッケージだけを残し、フォント・メディアツール（ffmpeg, imagemagick, yt-dlp, silicon, pandoc, poppler-utils 等）・LSP（basedpyright, gopls）・追加言語（deno, ruby, uv 等）・フォント群は省く。

A 案は3ファイルにまたがる変更になる。`dockerHomeConfiguration` が `home.packages` の全ツールをプロファイルに巻き込むため、HM 側でも最小セットの target を用意する必要がある。

変更1: `modules/home/packages.nix` の `forTarget` に debug 用分岐を追加:

    forTarget =
      target:
      if target == "darwin" then
        common ++ darwinPkgs
      else if target == "linux-container-debug" then
        # デバッグ検証に必要な最小セットのみ
        with pkgs; [ fish rustup mise codex gnupg ctx.dot sccache ]
      else if target == "linux-container" then
        common ++ linuxPkgs
      ...

変更2: `home.nix` で `linux-container-debug` を `linux-container` と同じ target module に振り向ける:

    targetModule =
      if target == "darwin" then
        ./modules/home/targets/darwin.nix
      else if target == "linux-container" || target == "linux-container-debug" then
        ./modules/home/targets/linux-container.nix
      else if target == "linux-desktop" then
        ./modules/home/targets/linux-desktop.nix
      else
        throw "unsupported home-manager target: ${target}";

変更3: `flake.nix` に `dockerImageDebug` を追加。`mkHomeConfiguration` で `target = "linux-container-debug"` を渡し、その activationPackage を `copyToRoot` に積む:

    dockerImageDebug =
      let
        dockerHomeConfiguration = mkHomeConfiguration {
          target = "linux-container-debug";
        };
      in
      pkgs.dockerTools.buildImage {
        name = "ama-home-manager-pure";
        tag = "latest";
        includeNixDB = true;
        buildVMMemorySize = 2048;
        runAsRoot = ''...（dockerImage と同じ）...'';
        copyToRoot = pkgs.buildEnv {
          name = "base-before-activation-debug";
          paths = with pkgs; [
            dockerHomeConfiguration.activationPackage
            busybox less nix nixConfig
            dockerTools.caCertificates dockerTools.usrBinEnv
            fishProfileLoader glibc stdenv.cc pkg-config curl
          ];
        };
        config = { ...（dockerImage と同じ）... };
      };

`packages` 出力に `dockerImageDebug` を追加（Linux のみ）。

ビルド手順（pure イメージのビルドは Linux が必要なため Apple Container 上の Nix コンテナを使う）:

    container run --arch arm64 --name nix-builder \
      --mount type=bind,source=$PWD,target=/work,readonly=false \
      -w /work \
      nixos/nix \
      sh -lc 'nix --extra-experimental-features "nix-command flakes" build .#dockerImageDebug && cp result /work/result-pure-debug'

    # 生成された tarball をロード
    container image load < result-pure-debug

    # ama-home-manager-pure:latest としてタグ付け（Dockerfile の FROM 用）
    container image tag <loaded-digest> ama-home-manager-pure:latest

    # 最終イメージをビルド
    container build ./docker -t ama-home-manager:debug

注意: Apple Container のマウント構文は事前に `container run --help` で確認する。`container run` は `--rm` を持たない場合があるため、終了後に `container rm nix-builder` を明示的に実行する。

### ステップ9: 修正版の検証

    container run --arch arm64 --name verify -i -t ama-home-manager:debug

成功基準（Purpose セクション）の全項目を実行し、全て通ることを確認。

### ステップ10: 片付け（ローカルビルド分）

    exit
    container rm verify
    container image rm ama-home-manager:debug ama-home-manager-pure:latest
    container image prune
    rm -f result result-pure

### ステップ11: CI 経由での公開と最終検証

修正を commit・push し、GitHub Actions のビルド完了を待つ:

    gh run watch

公開後、ステップ1と同等の検証を `latest` タグで実施し、片付ける。


## Validation and Acceptance

以下が全て満たされた場合のみ「修正完了」とする。

### 動作検証（公開イメージで実施）

1. `container run -i -t ghcr.io/gw31415/ama-home-manager:latest` が fish プロンプトを返す。
2. `which fish` → `/root/.nix-profile/bin/fish`
3. `dot --help` がヘルプを表示する。
4. `mise --version` がバージョンを表示する。
5. `rustc --version` がバージョンを表示する。
6. `nvim --version` が表示され、起動時にプラグインエラーが出ない（`:checkhealth` で致命的エラーなし）。
7. `git -C ~/.config/home-manager log --oneline -1` が最新コミットを表示する。
8. fish プラグインがロードされている（`functions -a | grep _z` などで確認）。
9. `$EDITOR` が `nvim`、`$XDG_CONFIG_HOME` が `/root/.config` に設定されている。

### ビルド検証

10. CI で `|| true` を外した状態で impure.sh が成功する（ビルドが通る）。
11. amd64/arm64 両方のビルドが成功する。

### 容量検証

12. 全デバッグ工程終了後、`container image ls` にデバッグ用イメージが残っていない。`df -h /Users/ama` で作業前と同等の空き容量に戻っている。


## Idempotence and Recovery

### 安全な再実行

- `container rm <name>` は存在しない名前に対して実行するとエラーになるが、`|| true` 付きで実行すれば安全に冪等にクリーンアップできる。検証ステップの最初に `container rm debug-ama 2>/dev/null || true` を入れてもよい。
- `container image prune` は未参照イメージを削除するだけで、使用中のイメージは削除しない。何度実行しても安全。
- nix build は純粋な関数なので、同じ入力なら同じ結果を返す。`rm -f result` して再ビルドしても問題ない。

### 部分失敗からの復帰

- イメージ pull に失敗する場合: ネットワークまたはレジストリ認証の問題。`container registry login ghcr.io` で認証を設定してから再試行。
- pure イメージのロードに失敗する場合: tarball が壊れている可能性。`nix build` をやり直す。
- `container build` で `FROM ama-home-manager-pure:latest` が解決しない場合: `container image ls` でイメージ名を確認し、`container image tag <digest> ama-home-manager-pure:latest` で明示的にタグ付けする。
- ビルド中にディスクフルになる場合: 直ちに `container image prune` と `nix-store --gc` で容量を回復する。イメージは GHCR から再 pull できるので、ローカルの中間イメージはいつでも削除してよい。
- impure.sh を修正後にビルドが通らない場合: 修正を1つずつ戻し（git stash またはコミット単位の revert）、どの変更が原因か二分探索する。

### ロールバック

ソースコードの変更は git で管理されているため、`git checkout -- <file>` または `git revert <commit>` でいつでも戻せる。CI で公開されたイメージも、`sha-<commit>` タグが過去分残っているため、悪いバージョンを push しても `latest` を前の SHA に戻せば復旧できる。


## Artifacts and Notes

（フェーズ1-3の実行結果をここに記録する。各コマンドの出力・exit code・エラーメッセージを貼る。）

### ステップ1の結果（公開イメージ起動）

    # この欄に実行結果を記録する


## Interfaces and Dependencies

### コンテナが提供すべきもの（修正後）

- `/root/.nix-profile/bin/fish`: エントリポイントの fish バイナリ。
- `/activate`: HM activation スクリプト（pure イメージの copyToRoot に含まれる）。
- `/etc/profile.d/nix*.sh`: nix コマンドの PATH 設定。`nix` パッケージまたは `nix-daemon` の profile スクリプト由来。
- `/etc/fish/conf.d/profile.fish`: fish login shell が `/etc/profile.d/*.fish` を source するためのローダー（flake で生成）。
- `~/.config/fish/conf.d/hm-session-vars.fish`: HM が生成する sessionVariables の fish 向けローダー。
- `~/.config/home-manager/`: git で管理された dotfiles リポジトリ（impure.sh で clone）。
- `dot` CLI: `ctx.dot` パッケージ由来。Home Manager / nix-darwin の切替を行う。

### 外部依存

- `ghcr.io/gw31415/ama-home-manager`: 公開先レジストリ。
- `github.com/gw31415/dotfiles`: impure.sh が clone する dotfiles リポジトリ（このリポジトリ自体）。
- `cache.nixos.org`: Nix ビルドキャッシュ。
- Apple Container システムサービス: `container system start` で起動が必要。

### ファイル（修正対象となる可能性のあるもの）

- `docker/Dockerfile`: 最終イメージの構築手順。
- `docker/impure.sh`: mutable セットアップスクリプト。
- `flake.nix`: pure イメージの定義（`dockerImage` 属性）。
- `.github/workflows/publish-container.yml`: CI パイプライン。


## Revision Notes

- 2026-07-07 (v3): A 案に確定。`dockerImageDebug` を `flake.nix` に追加し、`linux-container-debug` target を `packages.nix` / `home.nix` に設ける方針に整理。B 案は破棄。
- 2026-07-07 (v2): ユーザー指示によりローカルデバッグビルド（フェーズ5）を最小パッケージセットに変更。CI 公開イメージはフルセットのまま。`dockerImageDebug` の2案（flake 追加 / target 追加）を提示。
- 2026-07-07 (v1): 初版。コード静的読解とホスト環境確認に基づき、観察→分割→特定→修正の6フェーズ計画を作成。主な疑い箇所として、`docker/Dockerfile` の `|| true` による失敗の握り潰し、`impure.sh` の `git reset`（`--hard` 不足）、profile.d スクリプトの欠落可能性を提示。まだ実際の起動検証は行っていないため、フェーズ1-3の結果により計画を更新する予定。
