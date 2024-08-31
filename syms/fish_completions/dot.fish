complete -c dot -f

complete -c dot -n "not __fish_seen_subcommand_from $commands" -l update -s u -d "with updating the flake.lock"
complete -c dot -n "not __fish_seen_subcommand_from $commands" -l darwin -d "Switch also with nix-darwin (not only home-manager)"


function __fish_complete_dot_subcommand
    set subcmd (string sub -s 4 (string match -r 'sh \\S.+ ' (commandline -c))) >/dev/null 2>&1
	if test $status -ne 0
		set subcmd ""
	end
    complete -C $subcmd
end

complete -c dot -n __fish_use_subcommand -a sh -d "Enter \$SHELL in the home-manager dir"
complete -c dot -n '__fish_seen_subcommand_from sh' -a "(__fish_complete_dot_subcommand)"

complete -c dot -n __fish_use_subcommand -a gc -d "Nix garbage-collection"
complete -c dot -n '__fish_seen_subcommand_from gc' -l aggressive -d 'Aggressive garbage collection'
