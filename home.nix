{ config, pkgs, ... }:
let name = "ama"; in
{
  home.packages = with pkgs; [
    aria2
    asciinema
    bat
    carbon-now-cli
    chezmoi
    delta
    deno
    dotnet-sdk_7
    emacs
    eza
    ffmpeg
    fish
    flyctl
    fzf
    gh
    git-credential-manager
    go
    gopls
    hugo
    imagemagick
    jdupes
    jnv
    jq
    litecli
    mise
    mmv-go
    neovim
    nodejs
    pandoc
    poppler
    python3
    ripgrep
    rustup
    sccache
    silicon
    starship
    tectonic
    tmux
    typst
    wasmer
    wezterm
    wget
    yt-dlp
    zig
  ];

  home.file = {
    ".config" = {
      source = ./statics/config;
      recursive = true;
    };
    ".emacs.d" = {
      source = ./statics/emacs.d;
      recursive = true;
    };
    ".latexmkrc".source = ./statics/latexmkrc;

    ".config/nvim" = {
      source = config.lib.file.mkOutOfStoreSymlink ./nvim;
    };
    ".Brewfile" = {
      source = config.lib.file.mkOutOfStoreSymlink ./Brewfile;
    };
  };
  home.sessionVariables = {
    EDITOR = "nvim";
    RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
    SHELL = "${pkgs.fish}/bin/fish";
  };

  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    userName = "gw31415";
    extraConfig.credential.helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
    userEmail = "gw31415@amas.dev";
    delta.enable = true;
    ignores = [
      ".DS_Store"
      "kls_database.db"
      "flake.lock"
    ];
  };
  programs.fish = {
    enable = true;
    plugins = [
      { name = "z"; src = pkgs.fishPlugins.z; }
      { name = "fzf"; src = pkgs.fishPlugins.fzf; }
      { name = "autopair"; src = pkgs.fishPlugins.autopair; }
    ];
    shellAbbrs = {
      tree = "eza -T";
    };
    shellInit = ''
      if test -f /opt/homebrew/bin/brew
        eval (/opt/homebrew/bin/brew shellenv)
      end
      starship init fish | source
      if status is-interactive
        mise activate fish | source
      else
        mise activate fish --shims | source
      end
      if test -d /Applications/Android\ Studio.app/Contents/jbr/Contents/Home
        export JAVA_HOME=/Applications/Android\ Studio.app/Contents/jbr/Contents/Home
      end
      source "$HOME/.cargo/env.fish"
    '';
  };
  programs.go = {
    enable = true;
    goPath = ".go";
  };
  home = {
    username = name;
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${name}" else "/home/${name}";
    stateVersion = "24.05";
  };
  manual.manpages.enable = true;
}
