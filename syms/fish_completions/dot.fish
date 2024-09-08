complete -c dot -f

function __fish_dot_is_root_cmd
    for cmd in gc sh # <--- All subcommands
        if __fish_seen_subcommand_from $cmd
            return 1
        end
    end
end

complete -c dot -n "__fish_dot_is_root_cmd" -l home   -s h -d "Switch env of home-manager"
complete -c dot -n "__fish_dot_is_root_cmd" -l darwin -s d -d "Switch env of nix-darwin"
complete -c dot -n "__fish_dot_is_root_cmd" -l all    -s a -d "Switch all envs"
complete -c dot -n "__fish_dot_is_root_cmd" -l update -s u -d "fetch & update the flake.lock"

function __fish_complete_dot-sh_argcmd
    set subcmd (string sub -s 4 (string match -r 'sh \\S.+[ /]' (commandline -c))) >/dev/null 2>&1
	if test $status -ne 0
		set subcmd ""
	end
    set dir (pwd)
    cd $HOME/.config/home-manager
    complete -C $subcmd
    complete -C "$subcmd"-
    cd $dir
end

complete -c dot -n __fish_use_subcommand -a sh -d "Enter \$SHELL in the home-manager dir"
complete -c dot -n '__fish_seen_subcommand_from sh' -a "(__fish_complete_dot-sh_argcmd)"

complete -c dot -n __fish_use_subcommand -a gc -d "Nix garbage-collection"
complete -c dot -n '__fish_seen_subcommand_from gc' -l aggressive -d 'Aggressive garbage collection'
