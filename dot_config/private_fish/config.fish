if [ $TERM = "xterm-kitty" ]
	alias ssh="kitty +kitten ssh"
end

if test -f /opt/homebrew/bin/brew
	eval (/opt/homebrew/bin/brew shellenv)
end

if type -q opam
	eval (opam env)
end

if type -q rye
	set -x PATH "$HOME/.rye/shims" $PATH
end

# Rust compile cache
if type -q sccache
	export RUSTC_WRAPPER=(which sccache)
end

export LDFLAGS="-L/opt/homebrew/lib"; export CPPFLAGS="-I/opt/homebrew/include"

if type -q starship
	starship init fish | source
end
