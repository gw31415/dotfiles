# Nix を残しているマシン (nix-darwin の Mac、任意で `.#shared` の Linux) 用。
# Homebrew / mise の fish は /etc/fish を読まないため、Nix の PATH をここで通す。
# 05-brew と 10-mise より先に置き、両者を Nix より優先させる。
if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
end
# nix-darwin の environment.systemPackages (darwin-rebuild, comma など)。
if test -d /run/current-system/sw/bin
    fish_add_path -g /run/current-system/sw/bin
end
