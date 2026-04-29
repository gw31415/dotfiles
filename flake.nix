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
            fishProfileLoader = writeScriptDir "etc/fish/conf.d/profile.fish" ''
              if status --is-login
                source /etc/profile.d/*.fish
              end
            '';
            impureSh = writeScriptDir "root/impure.sh" (builtins.readFile ./impure.sh);
          in
          pkgs.dockerTools.buildImage {
            name = "ama-home-manager";
            tag = "latest";
            includeNixDB = true;
            buildVMMemorySize = 2048;

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

                impureSh
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
        dockerImageImpure =
          let
            pkgs = ctx.pkgs;
            fishCmd = [
              "/root/.nix-profile/bin/fish"
              "-l"
            ];
          in
          pkgs.runCommand "ama-home-manager-impure.tar.gz"
            {
              DOCKER_HOST =
                let
                  dockerHost = builtins.getEnv "DOCKER_HOST";
                in
                if dockerHost != "" then dockerHost else "tcp://host.docker.internal:23750";
              nativeBuildInputs = with pkgs; [
                docker-client
                gzip
              ];
              preferLocalBuild = true;
              allowSubstitutes = false;
            }
            ''
              set -euo pipefail

              if [ -z "''${DOCKER_HOST:-}" ] && [ ! -S /var/run/docker.sock ]; then
                echo "docker socket or DOCKER_HOST is required to build dockerImageImpure" >&2
                exit 1
              fi

              base_ref="ama-home-manager:latest"
              temp_base_ref="ama-home-manager:pure-build-$$"
              temp_impure_ref="ama-home-manager:impure-build-$$"
              cid=""
              previous_base_id="$(docker image inspect "$base_ref" --format '{{.Id}}' 2>/dev/null || true)"

              cleanup() {
                if [ -n "$cid" ]; then
                  docker rm -f "$cid" >/dev/null 2>&1 || true
                fi
                docker image rm -f "$temp_impure_ref" >/dev/null 2>&1 || true
                docker image rm -f "$temp_base_ref" >/dev/null 2>&1 || true

                if [ -n "$previous_base_id" ]; then
                  docker tag "$previous_base_id" "$base_ref" >/dev/null 2>&1 || true
                else
                  docker image rm -f "$base_ref" >/dev/null 2>&1 || true
                fi
              }
              trap cleanup EXIT

              docker load -i ${dockerImage} >/dev/null
              docker tag "$base_ref" "$temp_base_ref"

              cid="$(docker create \
                --env USER=root \
                --env LOGNAME=root \
                --env HOME=/root \
                --workdir /root \
                "$temp_base_ref" \
                sh -lc ' /root/impure.sh || true')"

              docker start -a "$cid" >/dev/null 2>&1 || true

              docker commit \
                --change 'CMD ${builtins.toJSON fishCmd}' \
                --change 'USER root' \
                --change 'WORKDIR /root' \
                --change 'ENV USER=root' \
                --change 'ENV LOGNAME=root' \
                --change 'ENV HOME=/root' \
                "$cid" \
                "$temp_impure_ref" >/dev/null

              docker save "$temp_impure_ref" | gzip -1 > "$out"
            '';
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
          inherit dockerImage dockerImageImpure;
        };

        apps.default = ctx.flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
        };
      }
    );
}
