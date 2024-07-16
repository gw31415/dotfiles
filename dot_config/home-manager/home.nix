{ pkgs, ... }:
let name = "ama"; in
{
  home.username = name;
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${name}" else "/home/${name}";
  home.stateVersion = "24.05";
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
    # ".screenrc".source = dotfiles/screenrc;
    ".latexmkrc".text = ''
      #!/usr/bin/env perl
      $latex            = 'uplatex -halt-on-error -synctex=1 -interaction=nonstopmode';
      $latex_silent     = 'uplatex -halt-on-error -synctex=1 -interaction=nonstopmode';
      $bibtex           = 'upbibtex %O %B';
      $biber            = 'biber --bblencoding=utf8 -u -U --output_safechars';
      $dvipdf           = 'dvipdfmx %O -o %D %S';
      $makeindex        = 'mendex %O -o %D %S';
      $max_repeat       = 5;
      $pdf_mode         = 3;
      @generated_exts   = (@generated_exts, 'dvi', 'synctex.gz', 'bbl');
    '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/ama/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
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

      # Rust compile cache
      export RUSTC_WRAPPER=(which sccache)

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
}
