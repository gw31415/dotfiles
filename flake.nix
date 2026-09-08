{
  description = "dotfiles and configurations for ama";

  inputs = {
    # INFO: nix-darwin-26.05 のリリースチェックが nixpkgs-YY.MM-darwin を要求するためこちらを採用
    #       (nixos-26.05 だと darwinSystem の eval が弾かれる)。
    #       中身はフル nixpkgs のため Linux でも eval・導入可。
    # WARN: Hydra は -darwin ブランチを Darwin 向けにビルド・テストするため、
    #       Linux のバイナリキャッシュは nixos-26.05 より薄くソースビルドに落ちやすい。
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    dot = {
      url = "github:gw31415/dot-cli";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  # NOTE: nix-darwin / darwinConfigurations はトップレベル出力にする。
  # eachSystem 配下に置くと `nix run .#nix-darwin` が derivation ではなく
  # set に解決され、`darwin-rebuild switch --flake .` の
  # `darwinConfigurations.<hostname>` 解決も失敗する。
  # Linux では home-manager のみ提供し、nix-darwin 系は除外される。
  outputs =
    { self, ... }@inputs:
    let
      env = import ./nix/env.nix;
      darwinSystem = "aarch64-darwin";
      mkCtx =
        system:
        inputs
        // {
          inherit system;
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          dot = inputs.dot.packages.${system}.default;
        };
      darwinCtx = mkCtx darwinSystem;

    in
    inputs.flake-utils.lib.eachSystem
      [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ]
      (
        system:
        let
          ctx = mkCtx system;
        in
        {
          packages = {
            default = ctx.dot;
            homeConfigurations.${env.username} = ctx.home-manager.lib.homeManagerConfiguration {
              pkgs = ctx.pkgs;
              modules = [
                ({ config, ... }: import ./nix/home.nix { inherit config ctx; })
              ];
            };
          };

          apps.default = inputs.flake-utils.lib.mkApp {
            drv = self.packages.${system}.default;
          };
        }
      )
    // {

      # Compatibility output for tools that still do `nix run .#nix-darwin`.
      nix-darwin = inputs.nix-darwin.packages.${darwinSystem}.default;

      darwinConfigurations.${env.hostname} = darwinCtx.nix-darwin.lib.darwinSystem {
        modules = [
          ({ pkgs, ... }: import ./nix/darwin.nix { ctx = darwinCtx; })
          darwinCtx.nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              # Rosetta(Intel)プレフィックスは使用していないため無効化
              # /usr/local/bin/brew がPATH優先度で /opt/homebrew/bin/brew より先に
              # 解決され、brew bundle がIntel prefixで実行されて失敗する問題を回避
              enableRosetta = false;
              user = env.username;
              autoMigrate = true;
              # Homebrew 6.0 Tap-Trust: 非公式tapをactivation時に自動trust
              trust.taps = [
                "jorgelbg/tap"
                "arto-app/tap"
                "anomalyco/tap"
                "macos-fuse-t/cask"
                "vorssaint/tap"
                "steipete/tap"
              ];
            };
          }
        ];
      };
    };
}
