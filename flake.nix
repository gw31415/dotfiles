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
          glibcLib = pkgs.lib.getLib pkgs.gcc.cc;
          dynamicLinkerName =
            {
              x86_64-linux = "ld-linux-x86-64.so.2";
              aarch64-linux = "ld-linux-aarch64.so.1";
            }
            .${system};
          dockerHomeConfiguration = mkHomeConfiguration {
            inherit system;
            target = "linux-container";
          };
          containerEnv = import ./modules/lib/container-env.nix {
            inherit env pkgs;
            activationPackage = dockerHomeConfiguration.activationPackage;
          };
        in
        pkgs.dockerTools.buildLayeredImage {
          name = "ama-home-manager";
          tag = "latest";
          includeNixDB = true;
          contents =
            with pkgs;
            [
              bashInteractive
              coreutils
              git
              fish
              iana-etc
              nix
              dockerTools.binSh
              dockerTools.caCertificates
              dockerTools.fakeNss
              dockerTools.usrBinEnv
            ]
            ++ [
              glibcLib
              dockerHomeConfiguration.activationPackage
            ];
          extraCommands = ''
            mkdir -p \
              lib \
              lib64 \
              tmp \
              home/${env.username} \
              home/${env.username}/.local/state/home-manager/gcroots \
              home/${env.username}/.local/state/nix/profiles \
              nix/var/nix/profiles/per-user/${env.username} \
              nix/var/nix/gcroots/per-user/${env.username} \
              etc/nix
            chmod u+rwx home/${env.username}
            ln -sf ${pkgs.stdenv.cc.bintools.dynamicLinker} lib/${dynamicLinkerName}
            ln -sf ${pkgs.stdenv.cc.bintools.dynamicLinker} lib64/${dynamicLinkerName}
            printf '%s\n' \
              'experimental-features = nix-command flakes' \
              'sandbox = false' \
              'filter-syscalls = false' \
              'build-users-group =' \
              > etc/nix/nix.conf
          '';
          config = {
            WorkingDir = containerEnv.containerHome;
            Env = containerEnv.envList;
            Cmd = [
              "${pkgs.fish}/bin/fish"
              "-l"
            ];
          };
        };
    in
    inputs.flake-utils.lib.eachSystem systems (
      system:
      let
        ctx = mkCtx system;
        pkgs = ctx.pkgs;
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
            runtimeInputs = [ pkgs.nvfetcher ];
            text = ''
              nvfetcher "$@"
            '';
          };
        };
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
