if test -f /opt/homebrew/bin/brew
	eval (/opt/homebrew/bin/brew shellenv)
end

# Rust compile cache
if type -q sccache
	export RUSTC_WRAPPER=(which sccache)
end

export LDFLAGS="-L/opt/homebrew/lib"; export CPPFLAGS="-I/opt/homebrew/include"

if type -q starship
	starship init fish | source
end

if type -q mise
	if status is-interactive
		mise activate fish | source
	else
		mise activate fish --shims | source
	end
end

if test -d /Applications/Android\ Studio.app/Contents/jbr/Contents/Home
	export JAVA_HOME=/Applications/Android\ Studio.app/Contents/jbr/Contents/Home
end

source "$HOME/.cargo/env.fish"

abbr neov neovide
