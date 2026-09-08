# Print an optspec for argparse to handle cmd's options that are independent of any subcommand.
function __fish_edisch_global_optspecs
	string join \n t/token= g/guild-id= text voice forum stage news category all y/yes h/help V/version
end

function __fish_edisch_needs_command
	# Figure out if the current invocation already has a command.
	set -l cmd (commandline -opc)
	set -e cmd[1]
	argparse -s (__fish_edisch_global_optspecs) -- $cmd 2>/dev/null
	or return
	if set -q argv[1]
		# Also print the command, so this can be used to figure out what it is.
		echo $argv[1]
		return 1
	end
	return 0
end

function __fish_edisch_using_subcommand
	set -l cmd (__fish_edisch_needs_command)
	test -z "$cmd"
	and return 1
	contains -- $cmd[1] $argv
end

complete -c edisch -n "__fish_edisch_needs_command" -s t -l token -d 'Bot token. If not provided, it will be read from the $DISCORD_TOKEN environment variable' -r
complete -c edisch -n "__fish_edisch_needs_command" -s g -l guild-id -d 'Guild ID. If not provided, it will be read from the $GUILD_ID environment variable' -r
complete -c edisch -n "__fish_edisch_needs_command" -l text -d 'Edit Text Channels'
complete -c edisch -n "__fish_edisch_needs_command" -l voice -d 'Edit Voice Channels'
complete -c edisch -n "__fish_edisch_needs_command" -l forum -d 'Edit Forum Channels'
complete -c edisch -n "__fish_edisch_needs_command" -l stage -d 'Edit Stage Channels'
complete -c edisch -n "__fish_edisch_needs_command" -l news -d 'Edit News Channels'
complete -c edisch -n "__fish_edisch_needs_command" -l category -d 'Edit Category Channels'
complete -c edisch -n "__fish_edisch_needs_command" -l all -d 'Edit All Channels'
complete -c edisch -n "__fish_edisch_needs_command" -s y -l yes -d 'Automatically confirm all changes'
complete -c edisch -n "__fish_edisch_needs_command" -s h -l help -d 'Print help'
complete -c edisch -n "__fish_edisch_needs_command" -s V -l version -d 'Print version'
complete -c edisch -n "__fish_edisch_needs_command" -f -a "export" -d 'Export all channel names to a file or stdout'
complete -c edisch -n "__fish_edisch_needs_command" -f -a "apply" -d 'Apply all channel names from a file or stdin'
complete -c edisch -n "__fish_edisch_needs_command" -f -a "completion" -d 'Generate shell completion'
complete -c edisch -n "__fish_edisch_needs_command" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c edisch -n "__fish_edisch_using_subcommand export" -s t -l token -d 'Bot token. If not provided, it will be read from the $DISCORD_TOKEN environment variable' -r
complete -c edisch -n "__fish_edisch_using_subcommand export" -s g -l guild-id -d 'Guild ID. If not provided, it will be read from the $GUILD_ID environment variable' -r
complete -c edisch -n "__fish_edisch_using_subcommand export" -s o -l output -d 'File to export to' -r -F
complete -c edisch -n "__fish_edisch_using_subcommand export" -s h -l help -d 'Print help'
complete -c edisch -n "__fish_edisch_using_subcommand apply" -s t -l token -d 'Bot token. If not provided, it will be read from the $DISCORD_TOKEN environment variable' -r
complete -c edisch -n "__fish_edisch_using_subcommand apply" -s g -l guild-id -d 'Guild ID. If not provided, it will be read from the $GUILD_ID environment variable' -r
complete -c edisch -n "__fish_edisch_using_subcommand apply" -s i -l input -d 'File to apply from' -r -F
complete -c edisch -n "__fish_edisch_using_subcommand apply" -s y -l yes -d 'Automatically confirm all changes'
complete -c edisch -n "__fish_edisch_using_subcommand apply" -s h -l help -d 'Print help'
complete -c edisch -n "__fish_edisch_using_subcommand completion" -s h -l help -d 'Print help'
complete -c edisch -n "__fish_edisch_using_subcommand help; and not __fish_seen_subcommand_from export apply completion help" -f -a "export" -d 'Export all channel names to a file or stdout'
complete -c edisch -n "__fish_edisch_using_subcommand help; and not __fish_seen_subcommand_from export apply completion help" -f -a "apply" -d 'Apply all channel names from a file or stdin'
complete -c edisch -n "__fish_edisch_using_subcommand help; and not __fish_seen_subcommand_from export apply completion help" -f -a "completion" -d 'Generate shell completion'
complete -c edisch -n "__fish_edisch_using_subcommand help; and not __fish_seen_subcommand_from export apply completion help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
