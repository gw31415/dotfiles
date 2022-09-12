function fish_prompt
    set -l cmd_status $status
    if test -n "$SSH_TTY"
        echo -n (set_color brred)"$USER"(set_color white)'@'(set_color yellow)(prompt_hostname)':'
    end

    echo (set_color blue)(prompt_pwd)' '

    set_color -o
    if test $cmd_status -eq 0
        echo -n (set_color yellow)'('(set_color green)'´‐_‐'(set_color yellow)') '
    else
        echo -n (set_color yellow)'('(set_color red)'´o_o'(set_color yellow)') '
    end
	echo -n (set_color cyan)'=3 '
    set_color normal
end
