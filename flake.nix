{
  description = "dotfiles and configurations for ama";

  inputs = {
    # INFO: nix-darwin-26.05 のリリースチェックが nixpkgs-YY.MM-darwin を要求するためこちらを採用
    #       (nixos-26.05 だと darwinSystem の eval が弾かれる)。
    #       中身はフル nixpkgs のため Linux でも eval・導入可。
    # WARN: Hydra は -darwin ブランチを Darwin 向けにビルド・テストするため、
    #       Linux のバイナリキャッシュは nixos-26.05 より薄くソースビルドに落ちやすい。
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # NOTE: user-level の管理 (symlink / shell / 開発ツール) は mise が正。
  #       Nix は「はみ出る部分」の薄い wrapper のみ:
  #       - Linux: packages.<system>.shared (共有ツール層, `nix profile install .#shared`)
  #       - macOS: darwinConfigurations (システム設定・フォント・常駐サービス)
  outputs =
    { nixpkgs, nix-darwin, ... }:
    let
      env = import ./nix/env.nix;
      darwinSystem = "aarch64-darwin";
      linuxSystems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      mkPkgs = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages = builtins.listToAttrs (
        map (system: {
          name = system;
          value = {
            shared = import ./nix/shared.nix { pkgs = mkPkgs system; };
          };
        }) linuxSystems
      );

      # Compatibility output for tools that still do `nix run .#nix-darwin`.
      nix-darwin = nix-darwin.packages.${darwinSystem}.default;

      darwinConfigurations.${env.hostname} = nix-darwin.lib.darwinSystem {
        modules = [
          ({ ... }: import ./nix/darwin.nix { pkgs = mkPkgs darwinSystem; })
        ];
      };
    };
}
