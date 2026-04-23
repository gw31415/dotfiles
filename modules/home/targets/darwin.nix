{ lib, ... }:
{
  programs.git.settings.credential.helper = "/usr/local/share/gcm-core/git-credential-manager";

  programs.fish.shellInit = lib.mkBefore ''
    if test -f /opt/homebrew/bin/brew
      eval (/opt/homebrew/bin/brew shellenv)
    end
    if test -d "/opt/homebrew/share/fish/completions"
      set -p fish_complete_path /opt/homebrew/share/fish/completions
    end
    if test -d "/opt/homebrew/share/fish/vendor_completions.d"
      set -p fish_complete_path /opt/homebrew/share/fish/vendor_completions.d
    end
    if test -d /Applications/Android\ Studio.app/Contents/jbr/Contents/Home
      export JAVA_HOME=/Applications/Android\ Studio.app/Contents/jbr/Contents/Home
    end
    if test -d "$HOME/Library/Android/sdk/platform-tools/"
      set -x PATH $HOME/Library/Android/sdk/platform-tools/ $PATH
    end
  '';
}
