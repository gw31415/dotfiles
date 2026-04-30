{
  description = "dotfiles and configurations for ama";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";

    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    dot = {
      url = "github:gw31415/dot-cli";
      inputs = {
        nixpkgs.follows = "nixpkgs-stable";
        flake-utils.follows = "flake-utils";
      };
    };
    rsplug = {
      url = "github:gw31415/rsplug.nvim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs =
    { self, ... }@inputs:
    let
      env = import ./env.nix;
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

    in
    inputs.flake-utils.lib.eachSystem systems (
      system:
      let
        ctx = inputs // {
          inherit system;
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-stable = import inputs.nixpkgs-stable {
            inherit system;
            config.allowUnfree = true;
          };
          dot = inputs.dot.packages.${system}.default;
          rsplug = inputs.rsplug.packages.${system}.default;
        };
        pkgs = ctx.pkgs;

        mkHomeConfiguration =
          { target }:
          ctx.home-manager.lib.homeManagerConfiguration {
            pkgs = ctx.pkgs;
            modules = [
              ({ config, ... }: import ./home.nix { inherit config ctx target; })
            ];
          };

        dockerImage =
          let
            pkgs = ctx.pkgs;
            dockerHomeConfiguration = mkHomeConfiguration {
              target = "linux-container";
            };
            nixConfig = pkgs.writeTextDir "etc/nix/nix.conf" ''
              substituters = https://cache.nixos.org/
              trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
              experimental-features = nix-command flakes
              build-users-group = nixbld
              allowed-users = *
              sandbox = false
            '';
            writeScriptDir =
              destination: text:
              pkgs.writeTextFile {
                inherit text destination;
                executable = true;
                name = "write-${builtins.baseNameOf destination}";
              };
            fishProfileLoader = writeScriptDir "/etc/fish/conf.d/profile.fish" ''
              if status --is-login
                source /etc/profile.d/*.fish
              end
            '';
          in
          pkgs.dockerTools.buildImage {
            name = "ama-home-manager-pure";
            tag = "latest";
            includeNixDB = true;
            buildVMMemorySize = 2048;

            # Requires: `system-features = kvm`
            runAsRoot = ''
              #!${pkgs.runtimeShell}
              ${pkgs.dockerTools.shadowSetup}

              chmod 1777 /tmp

              export USER=root LOGNAME=root HOME=/root
              mkdir -p /nix/var/nix/profiles/per-user/$USER $HOME/.config
              cp -r ${./.} $HOME/.config/home-manager
              chmod 644 -R $HOME/.config/home-manager

              # busybox によるもの
              addgroup -S nixbld
              adduser -G nixbld -D -H nixbld
            '';

            copyToRoot = pkgs.buildEnv {
              name = "base-before-activation";
              paths = with pkgs; [
                dockerHomeConfiguration.activationPackage

                busybox # Scratch ならこれは必要っぽい
                less

                nix
                nixConfig

                # 必要っぽいライブラリ
                dockerTools.caCertificates
                dockerTools.usrBinEnv

                fishProfileLoader
                glibc
                stdenv.cc
                pkg-config
                curl
              ];
            };
            config = {
              User = "root";
              Env = [
                "USER=root"
                "LOGNAME=root"
                "HOME=/root"
              ];
              WorkingDir = "/root";
            };
          };
      in
      {

        packages = {
          default = ctx.dot;
          homeConfigurations.${env.username} = mkHomeConfiguration {
            target = if pkgs.stdenv.isDarwin then "darwin" else "linux-container";
            # TODO: linux-desktop の自動分岐をどうするか
          };
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
          # Compatibility output for tools that still do `nix run .#nix-darwin`.
          nix-darwin = inputs.nix-darwin.packages.${system}.default;
          darwinConfigurations.${env.hostname} = ctx.nix-darwin.lib.darwinSystem {
            modules = [
              ({ pkgs, ... }: import ./darwin.nix { inherit ctx; })
              (ctx.nix-homebrew.darwinModules.nix-homebrew {
                lib = ctx.nix-darwin.lib;
                nix-homebrew = {
                  enable = true;
                  enableRosetta = true;
                  user = env.username;
                  autoMigrate = true;
                };
              })
            ];
          };
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
          inherit dockerImage;
        };

        apps.default = ctx.flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
        };
      }
    );
}
