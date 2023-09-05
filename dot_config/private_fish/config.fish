if [ $TERM = "xterm-kitty" ]
	alias ssh="kitty +kitten ssh"
end

if test -f /opt/homebrew/bin/brew
	eval (/opt/homebrew/bin/brew shellenv)
end

if type -q opam
	eval (opam env)
end

# Wasmer
export WASMER_DIR="$HOME/.wasmer"
[ -s "$WASMER_DIR/wasmer.sh" ] && source "$WASMER_DIR/wasmer.sh"

# if type -q docker
# export DOCKER_HOST=$(docker context inspect --format '{{.Endpoints.docker.Host}}')
# end

if type -q goneovim
	abbr -a nv goneovim --nofork
end

# Rust compile cache
if type -q sccache
	export RUSTC_WRAPPER=(which sccache)
end

export LDFLAGS="-L/opt/homebrew/lib"; export CPPFLAGS="-I/opt/homebrew/include"
