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

      mkCtx =
        system:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-stable = import inputs.nixpkgs-stable {
            inherit system;
            config.allowUnfree = true;
          };
        in
        inputs
        // {
          inherit
            pkgs
            pkgs-stable
            system
            ;
          dot = inputs.dot.packages.${system}.default;
          rsplug = inputs.rsplug.packages.${system}.default;
        };

      mkHomeModules = ctx: target: [
        ({ config, ... }: import ./home.nix { inherit config ctx target; })
      ];

      mkHomeConfiguration =
        {
          system,
          target,
        }:
        let
          ctx = mkCtx system;
        in
        ctx.home-manager.lib.homeManagerConfiguration {
          pkgs = ctx.pkgs;
          modules = mkHomeModules ctx target;
        };

      mkDockerImage =
        system:
        let
          ctx = mkCtx system;
          pkgs = ctx.pkgs;
          dockerHomeConfiguration = mkHomeConfiguration {
            inherit system;
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
          sources = import ./_sources/generated.nix {
            inherit (pkgs)
              dockerTools
              fetchFromGitHub
              fetchgit
              fetchurl
              ;
          };
        in
        pkgs.dockerTools.buildImage {
          name = "ama-home-manager";
          tag = "latest";
          includeNixDB = true;

          # fromImage = sources.distroless-cc-debian13.src;

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

            # Standard Unix コマンドによるもの
            # groupadd -r nixbld
            # useradd -g nixbld -M -r nixbld

            # busyboxによる色なしPAGERはつらい
            # cp -f {pkgs.less}/bin/less /sbin/less
          '';

          copyToRoot = pkgs.buildEnv {
            name = "base-before-activation";
            paths = with pkgs; [
              dockerHomeConfiguration.activationPackage
              busybox # Scratch ならこれは必要っぽい
              nix
              nixConfig

              # 必要っぽいライブラリ
              dockerTools.caCertificates
            ];
            pathsToLink = [ "/bin" ];
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

      defaultHomeTargetForSystem =
        system: if inputs.nixpkgs.lib.hasSuffix "-darwin" system then "darwin" else "linux-desktop";
    in
    inputs.flake-utils.lib.eachSystem systems (
      system:
      let
        ctx = mkCtx system;
        pkgs = ctx.pkgs;
        defaultHomeConfiguration = mkHomeConfiguration {
          inherit system;
          target = defaultHomeTargetForSystem system;
        };
      in
      {
        packages = {
          default = ctx.dot;
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
          # Compatibility output for tools that still do `nix run .#nix-darwin`.
          nix-darwin = inputs.nix-darwin.packages.${system}.default;
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
          dockerImage = mkDockerImage system;
        };

        apps.default = ctx.flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
        };
        apps.update-sources = ctx.flake-utils.lib.mkApp {
          drv = pkgs.writeShellApplication {
            name = "update-sources";
            runtimeInputs = with pkgs; [
              nvfetcher
              nix-prefetch-docker
            ];
            text = ''
              nvfetcher "$@"
            '';
          };
        };

        legacyPackages.homeConfigurations.${env.username} = defaultHomeConfiguration;
      }
    )
    // {
      darwinConfigurations.${env.hostname} =
        let
          ctx = mkCtx "aarch64-darwin";
        in
        ctx.nix-darwin.lib.darwinSystem {
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

      homeConfigurations."${env.username}-darwin" = mkHomeConfiguration {
        system = "aarch64-darwin";
        target = "darwin";
      };
      homeConfigurations."${env.username}-linux-container-aarch64" = mkHomeConfiguration {
        system = "aarch64-linux";
        target = "linux-container";
      };
      homeConfigurations."${env.username}-linux-container-x86_64" = mkHomeConfiguration {
        system = "x86_64-linux";
        target = "linux-container";
      };
      homeConfigurations."${env.username}-linux-desktop-aarch64" = mkHomeConfiguration {
        system = "aarch64-linux";
        target = "linux-desktop";
      };
      homeConfigurations."${env.username}-linux-desktop-x86_64" = mkHomeConfiguration {
        system = "x86_64-linux";
        target = "linux-desktop";
      };
    };
}
