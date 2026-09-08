function __fish_prompt_face
    echo -ns (set_color normal yellow) "("
    if test $argv[1] -eq 0
        echo -ns (set_color --bold green) " 'u'"
    else
        echo -ns (set_color --bold red) "´-_-"
    end
    echo -ns (set_color normal yellow) ")" (set_color cyan) " =3"
    echo -ns (set_color normal)
end

function __fish_prompt_simplegit
    command git rev-parse --is-inside-work-tree >/dev/null 2>/dev/null
    or return

    set -l branch
    set -l head
    set -l icon
    set -l color normal

    #
    # branch / detached
    #
    if set branch (command git symbolic-ref --quiet --short HEAD 2>/dev/null)
        set icon "✓"
        set head $branch
        set color brgreen
    else
        set icon "@"
        set head (command git rev-parse --short HEAD 2>/dev/null)
        set color brblack
    end

    #
    # special operations
    #
    set -l gitdir (command git rev-parse --git-dir 2>/dev/null)

    if test -f "$gitdir/MERGE_HEAD"
        set icon "!"
        set color brred
    else if test -d "$gitdir/rebase-merge" -o -d "$gitdir/rebase-apply"
        set icon "↻"
        set color bryellow
    else if test -f "$gitdir/CHERRY_PICK_HEAD"
        set icon ""
        set color bryellow
    else if test -f "$gitdir/BISECT_LOG"
        set icon "∵"
        set color brmagenta
    end

    #
    # upstream status
    #
    set -l upstream ""
    if command git rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>/dev/null
        set -l ahead (command git rev-list --count @{upstream}..HEAD 2>/dev/null)
        set -l behind (command git rev-list --count HEAD..@{upstream} 2>/dev/null)

        if test "$ahead" -gt 0 -a "$behind" -gt 0
            set upstream "⇅"
            set color brmagenta
        else if test "$ahead" -gt 0
            set upstream "↑$ahead"
            set color bryellow
        else if test "$behind" -gt 0
            set upstream "↓$behind"
            set color brblue
        end
    else
        set upstream "!up"
        set color red
    end

    #
    # status
    #
    set -l porcelain (command git status --porcelain 2>/dev/null)

    set -l staged ""
    set -l modified ""
    set -l untracked ""
    set -l conflicted ""

    for line in $porcelain
        set -l x (string sub -s 1 -l 1 -- $line)
        set -l y (string sub -s 2 -l 1 -- $line)

        if test "$x" = "?" -a "$y" = "?"
            set untracked "?"
            continue
        end

        if contains -- "$x" U A D
            set conflicted "!"
        else if test "$x" != " "
            set staged "+"
        end

        if contains -- "$y" U D
            set conflicted "!"
        else if test "$y" != " "
            set modified "~"
        end
    end
    
    #
    # stash
    #
    set -l stash ""
    if command git rev-parse --verify refs/stash >/dev/null 2>/dev/null
        set stash "S"
    end

    #
    # print
    #

    echo -n (set_color $color)
    echo -ns $icon $head " " (set_color normal) $upstream " " $staged $modified $untracked $conflicted $stash
end

function __fish_prompt_pwd_shorten_component -a component dir_length
    if test -z "$component"
        return
    end

    if test "$dir_length" -eq 0
        echo -n $component
        return
    end

    if test (string sub -s 1 -l 1 -- $component) = "."
        echo -n "."
        echo -n (string sub -s 2 -l $dir_length -- $component)
    else
        echo -n (string sub -s 1 -l $dir_length -- $component)
    end
end

function __fish_prompt_project_root -a dir max_depth
    set -l current $dir

    for depth in (seq 0 $max_depth)
        if test -d "$current/.git" -o -f "$current/.git" \
                -o -d "$current/.jj" \
                -o -d "$current/.hg" \
                -o -f "$current/flake.nix" \
                -o -f "$current/package.json" \
                -o -f "$current/Cargo.toml" \
                -o -f "$current/pyproject.toml" \
                -o -f "$current/go.mod" \
                -o -f "$current/deno.json" \
                -o -f "$current/mix.exs" \
                -o -f "$current/Gemfile"
            echo $current
            return 0
        end

        set -l parent (path dirname -- $current)
        test "$parent" = "$current"
        and break

        set current $parent
    end

    return 1
end

# プロジェクトルートを反転表示する prompt_pwd
function __fish_prompt_pwd
    set -l options h/help d/dir-length= D/full-length-dirs=
    argparse -n __fish_prompt_pwd $options -- $argv
    or return

    if set -q _flag_help
        __fish_print_help prompt_pwd
        return 0
    end

    set -q argv[1]
    or set argv $PWD

    set -ql _flag_d
    and set -l fish_prompt_pwd_dir_length $_flag_d

    set -q fish_prompt_pwd_dir_length
    or set -l fish_prompt_pwd_dir_length 1

    set -ql _flag_D
    and set -l fish_prompt_pwd_full_dirs $_flag_D

    set -q fish_prompt_pwd_full_dirs
    or set -l fish_prompt_pwd_full_dirs 1

    for path in $argv
        set -l raw (__fish_unexpand_tilde $path)

        if test "$fish_prompt_pwd_dir_length" -eq 0
            echo -s (set_color --bold cyan) $raw (set_color normal)
            continue
        end

        set -l parts (string split / -- $raw)
        set -l parts_count (count $parts)
        set -l preserve_from (math $parts_count - $fish_prompt_pwd_full_dirs + 1)

        if test "$fish_prompt_pwd_full_dirs" -eq 0
            set preserve_from (math $parts_count + 1)
        else if test "$preserve_from" -lt 1
            set preserve_from 1
        end

        set -l slash_count (math (count $parts) - 1)
        set -l root (__fish_prompt_project_root $path $slash_count)
        set -l root_part_count 0

        if test -n "$root"
            set -l root_raw (__fish_unexpand_tilde $root)
            set -l root_regex (string escape --style=regex -- $root_raw)
            if test "$root_raw" = "$raw"; or string match -q --regex -- "^$root_regex/" $raw
                set root_part_count (count (string split / -- $root_raw))
            end
        end

        echo -n (set_color --bold cyan)

        for i in (seq 1 $parts_count)
            if test $i -eq $root_part_count
                echo -n (set_color normal)(set_color --bold --reverse cyan)
            end

            if test $i -ge $preserve_from
                echo -n $parts[$i]
            else
                __fish_prompt_pwd_shorten_component $parts[$i] $fish_prompt_pwd_dir_length
            end

            if test $i -eq $root_part_count
                echo -n (set_color normal)(set_color --bold cyan)
            end

            if test $i -lt $parts_count
                echo -n /
            end
        end

        echo (set_color normal)
    end
end

function fish_prompt
    set -l last_status $pipestatus

    # プロンプトの構築
    echo -s (__fish_prompt_pwd --full-length-dirs 2) " " (__fish_prompt_simplegit)
    echo -s (__fish_prompt_face $last_status) " "
end
