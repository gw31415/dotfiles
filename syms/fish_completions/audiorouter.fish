# Print an optspec for argparse to handle cmd's options that are independent of any subcommand.
function __fish_audiorouter_global_optspecs
	string join \n c/config= q/quiet v/verbose h/help V/version
end

function __fish_audiorouter_needs_command
	# Figure out if the current invocation already has a command.
	set -l cmd (commandline -opc)
	set -e cmd[1]
	argparse -s (__fish_audiorouter_global_optspecs) -- $cmd 2>/dev/null
	or return
	if set -q argv[1]
		# Also print the command, so this can be used to figure out what it is.
		echo $argv[1]
		return 1
	end
	return 0
end

function __fish_audiorouter_using_subcommand
	set -l cmd (__fish_audiorouter_needs_command)
	test -z "$cmd"
	and return 1
	contains -- $cmd[1] $argv
end

complete -c audiorouter -n "__fish_audiorouter_needs_command" -s c -l config -d 'TOML configuration file to read' -r -F
complete -c audiorouter -n "__fish_audiorouter_needs_command" -s q -l quiet -d 'Suppress non-error output'
complete -c audiorouter -n "__fish_audiorouter_needs_command" -s v -l verbose -d 'Print extra diagnostics. Repeat for more detail'
complete -c audiorouter -n "__fish_audiorouter_needs_command" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c audiorouter -n "__fish_audiorouter_needs_command" -s V -l version -d 'Print version'
complete -c audiorouter -n "__fish_audiorouter_needs_command" -f -a "run" -d 'Start audio routing (default when no subcommand is given)'
complete -c audiorouter -n "__fish_audiorouter_needs_command" -f -a "check" -d 'Validate configuration and device availability, then exit'
complete -c audiorouter -n "__fish_audiorouter_needs_command" -f -a "list-devices" -d 'List available audio input/output devices, then exit'
complete -c audiorouter -n "__fish_audiorouter_needs_command" -f -a "config-path" -d 'Print the resolved configuration path, then exit'
complete -c audiorouter -n "__fish_audiorouter_needs_command" -f -a "dashboard" -d 'Launch the web dashboard (HTTP/SSE UI) in the default browser'
complete -c audiorouter -n "__fish_audiorouter_needs_command" -f -a "completions" -d 'Generate a shell completion script'
complete -c audiorouter -n "__fish_audiorouter_needs_command" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand run" -s c -l config -d 'TOML configuration file to read' -r -F
complete -c audiorouter -n "__fish_audiorouter_using_subcommand run" -s q -l quiet -d 'Suppress non-error output'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand run" -s v -l verbose -d 'Print extra diagnostics. Repeat for more detail'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand run" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand check" -s c -l config -d 'TOML configuration file to read' -r -F
complete -c audiorouter -n "__fish_audiorouter_using_subcommand check" -s q -l quiet -d 'Suppress non-error output'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand check" -s v -l verbose -d 'Print extra diagnostics. Repeat for more detail'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand check" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand list-devices" -s c -l config -d 'TOML configuration file to read' -r -F
complete -c audiorouter -n "__fish_audiorouter_using_subcommand list-devices" -s q -l quiet -d 'Suppress non-error output'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand list-devices" -s v -l verbose -d 'Print extra diagnostics. Repeat for more detail'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand list-devices" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand config-path" -s c -l config -d 'TOML configuration file to read' -r -F
complete -c audiorouter -n "__fish_audiorouter_using_subcommand config-path" -s q -l quiet -d 'Suppress non-error output'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand config-path" -s v -l verbose -d 'Print extra diagnostics. Repeat for more detail'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand config-path" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand dashboard" -s p -l port -d 'Port to bind the dashboard server on' -r
complete -c audiorouter -n "__fish_audiorouter_using_subcommand dashboard" -s c -l config -d 'TOML configuration file to read' -r -F
complete -c audiorouter -n "__fish_audiorouter_using_subcommand dashboard" -l host -d 'Expose the dashboard on the local network (bind 0.0.0.0)'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand dashboard" -l no-open -d 'Do not open the dashboard in the default browser'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand dashboard" -s q -l quiet -d 'Suppress non-error output'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand dashboard" -s v -l verbose -d 'Print extra diagnostics. Repeat for more detail'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand dashboard" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand completions" -s o -l output -d 'Output file [default: stdout]' -r -F
complete -c audiorouter -n "__fish_audiorouter_using_subcommand completions" -s c -l config -d 'TOML configuration file to read' -r -F
complete -c audiorouter -n "__fish_audiorouter_using_subcommand completions" -s q -l quiet -d 'Suppress non-error output'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand completions" -s v -l verbose -d 'Print extra diagnostics. Repeat for more detail'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand completions" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand help; and not __fish_seen_subcommand_from run check list-devices config-path dashboard completions help" -f -a "run" -d 'Start audio routing (default when no subcommand is given)'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand help; and not __fish_seen_subcommand_from run check list-devices config-path dashboard completions help" -f -a "check" -d 'Validate configuration and device availability, then exit'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand help; and not __fish_seen_subcommand_from run check list-devices config-path dashboard completions help" -f -a "list-devices" -d 'List available audio input/output devices, then exit'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand help; and not __fish_seen_subcommand_from run check list-devices config-path dashboard completions help" -f -a "config-path" -d 'Print the resolved configuration path, then exit'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand help; and not __fish_seen_subcommand_from run check list-devices config-path dashboard completions help" -f -a "dashboard" -d 'Launch the web dashboard (HTTP/SSE UI) in the default browser'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand help; and not __fish_seen_subcommand_from run check list-devices config-path dashboard completions help" -f -a "completions" -d 'Generate a shell completion script'
complete -c audiorouter -n "__fish_audiorouter_using_subcommand help; and not __fish_seen_subcommand_from run check list-devices config-path dashboard completions help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
