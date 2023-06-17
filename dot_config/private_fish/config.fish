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
