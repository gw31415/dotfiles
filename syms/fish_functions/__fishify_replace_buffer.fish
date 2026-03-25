function __fishify_replace_buffer
    set -l input (commandline)
    if test -z "$input"
        return
    end

    set -l output (fishify "$input")
    if test $status -ne 0
        return
    end

    commandline --replace -- $output
end
