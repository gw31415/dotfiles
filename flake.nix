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
    # neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
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
      # overlays = [
      #   inputs.neovim-nightly-overlay.overlays.default
      # ];

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
          containerHomeManagerRepo = self.outPath;
        in
        inputs
        // {
          inherit
            pkgs
            pkgs-stable
            system
            containerHomeManagerRepo
            ;
          dot = inputs.dot.packages.${system}.default;
          rsplug = inputs.rsplug.packages.${system}.default;
        };

      mkHomeModules =
        ctx: container:
        [
          (
            { config, ... }:
            import ./home.nix {
              inherit config ctx container;
            }
          )
          # { nixpkgs.overlays = overlays; }
        ];

      mkHomeConfiguration =
        {
          system,
          container ? false,
        }:
        let
          ctx = mkCtx system;
        in
        ctx.home-manager.lib.homeManagerConfiguration {
          pkgs = ctx.pkgs;
          modules = mkHomeModules ctx container;
        };

      mkDockerImage =
        system:
        let
          ctx = mkCtx system;
          pkgs = ctx.pkgs;
          caCertPath = "/etc/ssl/certs/ca-certificates.crt";
          containerHome = "/home/${env.username}";
          gccLib = pkgs.lib.getLib pkgs.gcc.cc;
          dockerHomeConfiguration = mkHomeConfiguration {
            inherit system;
            container = true;
          };
          caEnvVars = [
            "SSL_CERT_FILE"
            "NIX_SSL_CERT_FILE"
            "GIT_SSL_CAINFO"
            "CURL_CA_BUNDLE"
          ];
        in
        pkgs.dockerTools.buildLayeredImage {
          name = "ama-home-manager";
          tag = "latest";
          includeNixDB = true;
          contents = [
            pkgs.bashInteractive
            pkgs.coreutils
            pkgs.git
            pkgs.fish
            pkgs.iana-etc
            pkgs.nix
            pkgs.dockerTools.binSh
            pkgs.dockerTools.caCertificates
            pkgs.dockerTools.fakeNss
            pkgs.dockerTools.usrBinEnv
            gccLib
            dockerHomeConfiguration.activationPackage
          ];
          extraCommands = ''
            mkdir -p \
              lib64 \
              tmp \
              home/${env.username} \
              home/${env.username}/.local/state/home-manager/gcroots \
              home/${env.username}/.local/state/nix/profiles \
              nix/var/nix/profiles/per-user/${env.username} \
              nix/var/nix/gcroots/per-user/${env.username} \
              etc/nix
            chmod u+rwx home/${env.username}
            ln -sf ${pkgs.stdenv.cc.bintools.dynamicLinker} lib64/ld-linux-x86-64.so.2
            printf '%s\n' \
              'experimental-features = nix-command flakes' \
              'sandbox = false' \
              'filter-syscalls = false' \
              'build-users-group =' \
              > etc/nix/nix.conf
          '';
          config = {
            WorkingDir = containerHome;
            Env = [
              "HOME=${containerHome}"
              "XDG_STATE_HOME=${containerHome}/.local/state"
              "USER=${env.username}"
              "SHELL=${pkgs.fish}/bin/fish"
              "XDG_CONFIG_HOME=${containerHome}/.config"
              "HOME_MANAGER_ACTIVATE=${dockerHomeConfiguration.activationPackage}/activate"
              "HOME_MANAGER_HOME_PATH=${dockerHomeConfiguration.activationPackage}/home-path"
              "LD_LIBRARY_PATH=${gccLib}/lib"
              "PATH=${dockerHomeConfiguration.activationPackage}/home-path/bin:${pkgs.nix}/bin:${pkgs.fish}/bin:${pkgs.coreutils}/bin:${pkgs.bashInteractive}/bin"
              "TERM=xterm-256color"
            ] ++ map (name: "${name}=${caCertPath}") caEnvVars;
            Cmd = [ "${pkgs.fish}/bin/fish" "-l" ];
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
        packages =
          {
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

      homeConfigurations.${env.username} = mkHomeConfiguration {
        system = "aarch64-darwin";
      };
      homeConfigurations."${env.username}-docker-aarch64-linux" = mkHomeConfiguration {
        system = "aarch64-linux";
        container = true;
      };
      homeConfigurations."${env.username}-docker-x86_64-linux" = mkHomeConfiguration {
        system = "x86_64-linux";
        container = true;
      };
    };
}
