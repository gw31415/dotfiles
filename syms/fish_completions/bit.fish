function __fish_bit_command_tokens
    set -l words (commandline -opc)
    if test (count $words) -eq 0
        return
    end

    set -e words[1]

    set -l i 1
    while test $i -le (count $words)
        set -l word $words[$i]
        switch $word
            case -C -c
                set i (math $i + 2)
                continue
            case '-*'
                set i (math $i + 1)
                continue
            case '*'
                echo $words[$i..-1]
                return
        end
    end
end

function __fish_bit_no_subcommand
    test (count (__fish_bit_command_tokens)) -eq 0
end

function __fish_bit_using_command
    set -l tokens (__fish_bit_command_tokens)
    if test (count $tokens) -eq 0
        return 1
    end

    for cmd in $argv
        if test "$tokens[1]" = "$cmd"
            return 0
        end
    end

    return 1
end

function __fish_bit_ai_no_subcommand
    set -l tokens (__fish_bit_command_tokens)
    if test (count $tokens) -lt 1
        return 1
    end

    test "$tokens[1]" = ai
    or return 1

    test (count $tokens) -eq 1
end

function __fish_bit_ai_using_subcommand
    set -l tokens (__fish_bit_command_tokens)
    if test (count $tokens) -lt 2
        return 1
    end

    test "$tokens[1]" = ai
    or return 1

    for subcmd in $argv
        if test "$tokens[2]" = "$subcmd"
            return 0
        end
    end

    return 1
end

function __fish_bit_refs
    git for-each-ref --format='%(refname:short)' refs/heads/ refs/tags/ refs/remotes/ 2>/dev/null
end

function __fish_bit_heads
    git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null
end

function __fish_bit_tags
    git for-each-ref --format='%(refname:short)' refs/tags/ 2>/dev/null
end

function __fish_bit_remotes
    git remote 2>/dev/null
end

complete -c bit -e

set -g __bit_commands \
    'add	Add file contents to the index' \
    'ai	AI helpers (rebase, merge, commit, cherry-pick, revert)' \
    'am	Apply a series of patches from a mailbox' \
    'apply	Apply a patch to files and/or to the index' \
    'bisect	Find by binary search the change that introduced a bug' \
    'blame	Show what revision and author last modified each line' \
    'branch	List, create, or delete branches' \
    'bundle	Create, verify, list-heads, and unbundle Git bundles' \
    'cat	Show file contents from a remote repository' \
    'cat-file	Provide content or type info for repository objects' \
    'check-attr	Display gitattributes information' \
    'check-ignore	Check whether paths are excluded by .gitignore' \
    'check-mailmap	Show canonical names and email addresses of contacts' \
    'check-ref-format	Ensure that a reference name is well formed' \
    'checkout	Switch branches or restore working tree files' \
    'checkout-index	Copy files from the index to the working tree' \
    'cherry	Find commits yet to be applied to upstream' \
    'cherry-pick	Apply the changes from existing commits' \
    'clean	Remove untracked files from the working tree' \
    'clone	Clone a repository into a new directory' \
    'column	Display data in columns' \
    'commit	Record changes to the repository' \
    'completion	Generate shell completion scripts' \
    'config	Get and set repository options' \
    'count-objects	Count unpacked objects and their disk consumption' \
    'credential	Retrieve and store user credentials' \
    'debug	Debug and inspect hub internals' \
    'describe	Give an object a human readable name based on a ref' \
    'diff	Show changes between commits, commit and working tree, etc' \
    'diff-files	Compare files in the working tree and index' \
    'difftool	Show changes using common diff tools' \
    'fast-export	Output a fast-import-compatible stream' \
    'fast-import	Backend for fast Git data importers' \
    'fetch	Download objects and refs from another repository' \
    'fetch-pack	Receive missing objects from another repository' \
    'fmt-merge-msg	Produce a merge commit message' \
    'format-patch	Prepare patches for e-mail submission' \
    'fsck	Verify the connectivity and validity of objects' \
    'gc	Cleanup unnecessary files and optimize the local repository' \
    'get-tar-commit-id	Extract commit ID from an archive created by git archive' \
    'grep	Print lines matching a pattern' \
    'hash-object	Compute object ID and optionally creates a blob' \
    'help	Show help information' \
    'hq	ghq-compatible repository management' \
    'http-fetch	Download objects via dumb HTTP' \
    'hub	Deprecated: use bit pr / bit issue / bit debug instead' \
    'index-pack	Build pack index file for an existing packed archive' \
    'init	Create an empty Git repository' \
    'interpret-trailers	Add or parse trailers in commit messages' \
    'issue	Manage issues' \
    'log	Show commit logs' \
    'ls-files	Show information about files in the index' \
    'ls-remote	List references in a remote repository' \
    'ls-tree	List the contents of a tree object' \
    'mailinfo	Extract patch info from a single e-mail message' \
    'mailsplit	Split mbox file into individual messages' \
    'maintenance	Run tasks to optimize Git repository data' \
    'mcp	Run bit MCP server (stdio)' \
    'merge	Join two or more development histories together' \
    'merge-base	Find common ancestor between commits' \
    'merge-index	Run a merge for each unmerged file in the index' \
    'merge-one-file	Standard merge helper for merge-index' \
    'mktag	Create a validated tag object' \
    'mktree	Build a tree-object from ls-tree formatted text' \
    'multi-pack-index	Write and verify multi-pack-indexes' \
    'mv	Move or rename a file, a directory, or a symlink' \
    'name-rev	Find symbolic names for given revs' \
    'notes	Add or inspect object notes' \
    'pack-objects	Create a packed archive of objects' \
    'pack-refs	Pack heads and tags for efficient repository access' \
    'patch-id	Compute a stable patch identifier' \
    'pr	Manage pull requests' \
    'prune	Prune all unreachable objects from the object database' \
    'prune-packed	Remove extra objects that are already in pack files' \
    'pull	Fetch from and integrate with another repository' \
    'push	Update remote refs along with associated objects' \
    'quiltimport	Import a quilt patch series' \
    'range-diff	Compare two commit ranges' \
    'read-tree	Read tree information into the index' \
    'rebase	Reapply commits on top of another base tip' \
    'rebase-ai	AI-assisted rebase conflict resolution' \
    'receive-pack	Receive what is pushed into the repository' \
    'reflog	Manage reflog information' \
    'relay	Relay-based repository sharing (serve, sync)' \
    'remote	Manage set of tracked repositories' \
    'repo	Run regular bit command without workspace translation' \
    'repack	Pack unpacked objects in a repository' \
    'request-pull	Generate a summary of pending changes' \
    'rerere	Reuse recorded resolution of conflicted merges' \
    'reset	Reset current HEAD to the specified state' \
    'restore	Restore working tree files' \
    'rev-list	List commit objects in reverse chronological order' \
    'rev-parse	Parse revision specifications' \
    'revert	Revert some existing commits' \
    'rm	Remove files from the working tree and from the index' \
    'send-pack	Push objects over git protocol to another repository' \
    'shortlog	Summarize git log output' \
    'show	Show various types of objects' \
    'show-branch	Show branches and their commits' \
    'show-branches	Show branches and their commits' \
    'show-index	Show packed archive index' \
    'show-ref	List references in a local repository' \
    'sparse-checkout	Initialize and modify the sparse-checkout config' \
    'stash	Stash the changes in a dirty working directory' \
    'status	Show the working tree status' \
    'stripspace	Clean up whitespace in text' \
    'subdir-clone	Clone subdirectory as independent repository' \
    'submodule	Initialize, update or inspect submodules' \
    'switch	Switch branches' \
    'symbolic-ref	Read, modify and delete symbolic refs' \
    'tag	Create, list, delete tag objects' \
    'tree	List tree entries from a remote repository (porcelain)' \
    'unpack-file	Create a temp file holding blob contents' \
    'unpack-objects	Unpack objects from a packed archive' \
    'update-index	Register file contents in the index' \
    'update-ref	Update the object name stored in a ref safely' \
    'update-server-info	Update auxiliary info for dumb HTTP serving' \
    'upload-archive	Send archive back to git-archive --remote' \
    'upload-pack	Send objects packed back to git-fetch-pack' \
    'var	Print a Git logical variable' \
    'verify-commit	Verify the GPG signature of commits' \
    'verify-pack	Validate packed Git archive files' \
    'verify-tag	Verify the GPG signature of tags' \
    'web--browse	Open URL in a web browser' \
    'worktree	Manage multiple working trees' \
    'workspace	Manage hierarchical bit workspace projects' \
    'write-tree	Create a tree object from the current index' \
    'ws	Shortcut for workspace' \
    'x/doc	Experimental wiki-like docs and memo storage inside .bit/docs' \
    'x/hooks	Manage hooks used by bit commands'

set -g __bit_ai_subcommands \
    'rebase	AI-assisted rebase conflict resolution' \
    'merge	AI-assisted merge conflict resolution' \
    'commit	AI-assisted commit message workflow' \
    'cherry-pick	AI-assisted cherry-pick conflict resolution' \
    'revert	AI-assisted revert conflict resolution'

set -g __bit_remote_subcommands \
    'add	Add a remote' \
    'remove	Remove a remote' \
    'rename	Rename a remote' \
    'set-url	Set remote URL' \
    'get-url	Get remote URL' \
    'show	Show remote info' \
    'prune	Prune stale refs'

set -g __bit_stash_subcommands \
    'push	Save changes' \
    'pop	Apply and remove stash' \
    'apply	Apply stash' \
    'drop	Remove stash' \
    'list	List stashes' \
    'show	Show stash diff' \
    'clear	Remove all stashes' \
    'create	Create stash object'

set -g __bit_workspace_subcommands \
    'init	Initialize workspace' \
    'status	Show workspace status' \
    'commit	Create workspace commit' \
    'push	Push workspace changes' \
    'run	Run workspace task' \
    'export	Export workspace data' \
    'doctor	Run workspace diagnostics' \
    'help	Show workspace help'

complete -c bit -n '__fish_bit_no_subcommand' -s C -r -d 'Change directory'
complete -c bit -n '__fish_bit_no_subcommand' -s c -r -d 'Set config'
complete -c bit -n '__fish_bit_no_subcommand' -l bare -d 'Treat as bare repository'
complete -c bit -n '__fish_bit_no_subcommand' -s h -l help -d 'Show help'
complete -c bit -n '__fish_bit_no_subcommand' -s v -l version -d 'Show version'
complete -c bit -n '__fish_bit_no_subcommand' -f -a '$__bit_commands'

complete -c bit -n '__fish_bit_using_command help repo' -f -a '$__bit_commands'
complete -c bit -n '__fish_bit_using_command completion' -f -a 'bash zsh fish'

complete -c bit -n '__fish_bit_using_command checkout switch' -s b -r -d 'Create and checkout new branch'
complete -c bit -n '__fish_bit_using_command checkout switch' -s B -r -d 'Create or reset and checkout branch'
complete -c bit -n '__fish_bit_using_command checkout switch' -l detach -d 'Detach HEAD'
complete -c bit -n '__fish_bit_using_command checkout switch' -s f -l force -d 'Force checkout'
complete -c bit -n '__fish_bit_using_command checkout switch' -l merge -d 'Merge local modifications'
complete -c bit -n '__fish_bit_using_command checkout switch' -s q -l quiet -d 'Quiet'
complete -c bit -n '__fish_bit_using_command checkout switch' -s t -l track -d 'Set up tracking'
complete -c bit -n '__fish_bit_using_command checkout switch' -l no-track -d 'Do not set up tracking'
complete -c bit -n '__fish_bit_using_command checkout switch' -f -a '(__fish_bit_refs)'

complete -c bit -n '__fish_bit_using_command branch' -s d -l delete -d 'Delete branch'
complete -c bit -n '__fish_bit_using_command branch' -s D -d 'Force delete branch'
complete -c bit -n '__fish_bit_using_command branch' -s m -l move -d 'Rename branch'
complete -c bit -n '__fish_bit_using_command branch' -s M -d 'Force rename branch'
complete -c bit -n '__fish_bit_using_command branch' -s c -l copy -d 'Copy branch'
complete -c bit -n '__fish_bit_using_command branch' -s C -d 'Force copy branch'
complete -c bit -n '__fish_bit_using_command branch' -s l -l list -d 'List branches'
complete -c bit -n '__fish_bit_using_command branch' -s a -l all -d 'List all branches'
complete -c bit -n '__fish_bit_using_command branch' -s r -l remotes -d 'List remote branches'
complete -c bit -n '__fish_bit_using_command branch' -l show-current -d 'Show current branch'
complete -c bit -n '__fish_bit_using_command branch' -l set-upstream-to -r -a '(__fish_bit_refs)' -d 'Set upstream'
complete -c bit -n '__fish_bit_using_command branch' -l unset-upstream -d 'Unset upstream'
complete -c bit -n '__fish_bit_using_command branch' -s v -l verbose -d 'Verbose'
complete -c bit -n '__fish_bit_using_command branch' -l merged -r -a '(__fish_bit_refs)' -d 'List merged branches'
complete -c bit -n '__fish_bit_using_command branch' -l no-merged -r -a '(__fish_bit_refs)' -d 'List unmerged branches'
complete -c bit -n '__fish_bit_using_command branch' -l sort -r -d 'Sort key'
complete -c bit -n '__fish_bit_using_command branch' -l contains -r -a '(__fish_bit_refs)' -d 'Branches containing commit'
complete -c bit -n '__fish_bit_using_command branch' -l no-contains -r -a '(__fish_bit_refs)' -d 'Branches not containing commit'
complete -c bit -n '__fish_bit_using_command branch' -f -a '(__fish_bit_heads)'

complete -c bit -n '__fish_bit_using_command merge' -l no-commit -d 'Do not commit'
complete -c bit -n '__fish_bit_using_command merge' -l squash -d 'Squash commits'
complete -c bit -n '__fish_bit_using_command merge' -l no-ff -d 'Create merge commit'
complete -c bit -n '__fish_bit_using_command merge' -l ff-only -d 'Fast-forward only'
complete -c bit -n '__fish_bit_using_command merge' -l ff -d 'Fast-forward if possible'
complete -c bit -n '__fish_bit_using_command merge' -l edit -d 'Edit merge message'
complete -c bit -n '__fish_bit_using_command merge' -l no-edit -d 'Accept auto merge message'
complete -c bit -n '__fish_bit_using_command merge' -l stat -d 'Show diffstat'
complete -c bit -n '__fish_bit_using_command merge' -l no-stat -d 'Hide diffstat'
complete -c bit -n '__fish_bit_using_command merge' -l log -d 'Add log to merge message'
complete -c bit -n '__fish_bit_using_command merge' -l no-log -d 'Omit log'
complete -c bit -n '__fish_bit_using_command merge' -s s -l strategy -r -d 'Merge strategy'
complete -c bit -n '__fish_bit_using_command merge' -s X -l strategy-option -r -d 'Strategy option'
complete -c bit -n '__fish_bit_using_command merge' -l abort -d 'Abort merge'
complete -c bit -n '__fish_bit_using_command merge' -l continue -d 'Continue merge'
complete -c bit -n '__fish_bit_using_command merge' -l quit -d 'Quit merge'
complete -c bit -n '__fish_bit_using_command merge' -l allow-unrelated-histories -d 'Allow unrelated histories'
complete -c bit -n '__fish_bit_using_command merge' -s m -r -d 'Merge message'
complete -c bit -n '__fish_bit_using_command merge' -f -a '(__fish_bit_refs)'

complete -c bit -n '__fish_bit_using_command rebase rebase-ai' -l onto -r -a '(__fish_bit_refs)' -d 'Rebase onto'
complete -c bit -n '__fish_bit_using_command rebase rebase-ai' -l abort -d 'Abort rebase'
complete -c bit -n '__fish_bit_using_command rebase rebase-ai' -l continue -d 'Continue rebase'
complete -c bit -n '__fish_bit_using_command rebase rebase-ai' -l skip -d 'Skip current patch'
complete -c bit -n '__fish_bit_using_command rebase rebase-ai' -l quit -d 'Quit rebase'
complete -c bit -n '__fish_bit_using_command rebase rebase-ai' -s i -l interactive -d 'Interactive rebase'
complete -c bit -n '__fish_bit_using_command rebase rebase-ai' -l keep-empty -d 'Keep empty commits'
complete -c bit -n '__fish_bit_using_command rebase rebase-ai' -l no-keep-empty -d 'Drop empty commits'
complete -c bit -n '__fish_bit_using_command rebase rebase-ai' -l rebase-merges -d 'Rebase merge commits'
complete -c bit -n '__fish_bit_using_command rebase rebase-ai' -l no-rebase-merges -d 'Do not rebase merge commits'
complete -c bit -n '__fish_bit_using_command rebase rebase-ai' -l stat -d 'Show diffstat'
complete -c bit -n '__fish_bit_using_command rebase rebase-ai' -l no-stat -d 'Hide diffstat'
complete -c bit -n '__fish_bit_using_command rebase rebase-ai' -f -a '(__fish_bit_refs)'

complete -c bit -n '__fish_bit_ai_no_subcommand' -f -a '$__bit_ai_subcommands'

complete -c bit -n '__fish_bit_ai_using_subcommand rebase' -l onto -r -a '(__fish_bit_refs)' -d 'Rebase onto'
complete -c bit -n '__fish_bit_ai_using_subcommand rebase' -l abort -d 'Abort rebase'
complete -c bit -n '__fish_bit_ai_using_subcommand rebase' -l continue -d 'Continue rebase'
complete -c bit -n '__fish_bit_ai_using_subcommand rebase' -l skip -d 'Skip current patch'
complete -c bit -n '__fish_bit_ai_using_subcommand rebase' -l quit -d 'Quit rebase'
complete -c bit -n '__fish_bit_ai_using_subcommand rebase' -s i -l interactive -d 'Interactive rebase'
complete -c bit -n '__fish_bit_ai_using_subcommand rebase' -l keep-empty -d 'Keep empty commits'
complete -c bit -n '__fish_bit_ai_using_subcommand rebase' -l no-keep-empty -d 'Drop empty commits'
complete -c bit -n '__fish_bit_ai_using_subcommand rebase' -l rebase-merges -d 'Rebase merge commits'
complete -c bit -n '__fish_bit_ai_using_subcommand rebase' -l no-rebase-merges -d 'Do not rebase merge commits'
complete -c bit -n '__fish_bit_ai_using_subcommand rebase' -l stat -d 'Show diffstat'
complete -c bit -n '__fish_bit_ai_using_subcommand rebase' -l no-stat -d 'Hide diffstat'
complete -c bit -n '__fish_bit_ai_using_subcommand rebase merge commit cherry-pick revert' -l model -r -d 'Provider model'
complete -c bit -n '__fish_bit_ai_using_subcommand rebase merge commit cherry-pick revert' -l max-ai-rounds -r -d 'Maximum AI resolution loops'
complete -c bit -n '__fish_bit_ai_using_subcommand rebase merge commit cherry-pick revert' -l agent-loop -d 'Use agent loop mode'
complete -c bit -n '__fish_bit_ai_using_subcommand rebase merge commit cherry-pick revert' -l agent-max-steps -r -d 'Agent steps per round'
complete -c bit -n '__fish_bit_ai_using_subcommand rebase' -f -a '(__fish_bit_refs)'

complete -c bit -n '__fish_bit_ai_using_subcommand merge' -l no-commit -d 'Do not commit'
complete -c bit -n '__fish_bit_ai_using_subcommand merge' -l squash -d 'Squash commits'
complete -c bit -n '__fish_bit_ai_using_subcommand merge' -l no-ff -d 'Create merge commit'
complete -c bit -n '__fish_bit_ai_using_subcommand merge' -l ff-only -d 'Fast-forward only'
complete -c bit -n '__fish_bit_ai_using_subcommand merge' -l ff -d 'Fast-forward if possible'
complete -c bit -n '__fish_bit_ai_using_subcommand merge' -l edit -d 'Edit merge message'
complete -c bit -n '__fish_bit_ai_using_subcommand merge' -l no-edit -d 'Accept auto merge message'
complete -c bit -n '__fish_bit_ai_using_subcommand merge' -l stat -d 'Show diffstat'
complete -c bit -n '__fish_bit_ai_using_subcommand merge' -l no-stat -d 'Hide diffstat'
complete -c bit -n '__fish_bit_ai_using_subcommand merge' -l log -d 'Add log to merge message'
complete -c bit -n '__fish_bit_ai_using_subcommand merge' -l no-log -d 'Omit log'
complete -c bit -n '__fish_bit_ai_using_subcommand merge' -s s -l strategy -r -d 'Merge strategy'
complete -c bit -n '__fish_bit_ai_using_subcommand merge' -s X -l strategy-option -r -d 'Strategy option'
complete -c bit -n '__fish_bit_ai_using_subcommand merge' -l abort -d 'Abort merge'
complete -c bit -n '__fish_bit_ai_using_subcommand merge' -l continue -d 'Continue merge'
complete -c bit -n '__fish_bit_ai_using_subcommand merge' -l quit -d 'Quit merge'
complete -c bit -n '__fish_bit_ai_using_subcommand merge' -l allow-unrelated-histories -d 'Allow unrelated histories'
complete -c bit -n '__fish_bit_ai_using_subcommand merge' -s m -r -d 'Merge message'
complete -c bit -n '__fish_bit_ai_using_subcommand merge' -f -a '(__fish_bit_refs)'

complete -c bit -n '__fish_bit_ai_using_subcommand commit' -l split -d 'Split mixed changes into logical units'
complete -c bit -n '__fish_bit_ai_using_subcommand commit' -s m -l message -r -d 'Commit message'
complete -c bit -n '__fish_bit_ai_using_subcommand commit' -s a -l all -d 'Commit all modified files'
complete -c bit -n '__fish_bit_ai_using_subcommand commit' -l amend -d 'Amend last commit'
complete -c bit -n '__fish_bit_ai_using_subcommand commit' -l no-edit -d 'Reuse existing message'
complete -c bit -n '__fish_bit_ai_using_subcommand commit' -s e -l edit -d 'Edit message'
complete -c bit -n '__fish_bit_ai_using_subcommand commit' -l allow-empty -d 'Allow empty commit'
complete -c bit -n '__fish_bit_ai_using_subcommand commit' -l allow-empty-message -d 'Allow empty message'
complete -c bit -n '__fish_bit_ai_using_subcommand commit' -l author -r -d 'Author'
complete -c bit -n '__fish_bit_ai_using_subcommand commit' -l date -r -d 'Date'
complete -c bit -n '__fish_bit_ai_using_subcommand commit' -s s -l signoff -d 'Add Signed-off-by'
complete -c bit -n '__fish_bit_ai_using_subcommand commit' -l dry-run -d 'Dry run'
complete -c bit -n '__fish_bit_ai_using_subcommand commit' -s v -l verbose -d 'Verbose'

complete -c bit -n '__fish_bit_ai_using_subcommand cherry-pick' -s e -l edit -d 'Edit message'
complete -c bit -n '__fish_bit_ai_using_subcommand cherry-pick' -s n -l no-commit -d 'Do not commit'
complete -c bit -n '__fish_bit_ai_using_subcommand cherry-pick' -s m -l mainline -r -d 'Mainline parent'
complete -c bit -n '__fish_bit_ai_using_subcommand cherry-pick' -l abort -d 'Abort cherry-pick'
complete -c bit -n '__fish_bit_ai_using_subcommand cherry-pick' -l continue -d 'Continue cherry-pick'
complete -c bit -n '__fish_bit_ai_using_subcommand cherry-pick' -l quit -d 'Quit cherry-pick'
complete -c bit -n '__fish_bit_ai_using_subcommand cherry-pick' -l skip -d 'Skip current patch'
complete -c bit -n '__fish_bit_ai_using_subcommand cherry-pick' -f -a '(__fish_bit_refs)'

complete -c bit -n '__fish_bit_ai_using_subcommand revert' -s e -l edit -d 'Edit message'
complete -c bit -n '__fish_bit_ai_using_subcommand revert' -s n -l no-commit -d 'Do not commit'
complete -c bit -n '__fish_bit_ai_using_subcommand revert' -s m -l mainline -r -d 'Mainline parent'
complete -c bit -n '__fish_bit_ai_using_subcommand revert' -l abort -d 'Abort revert'
complete -c bit -n '__fish_bit_ai_using_subcommand revert' -l continue -d 'Continue revert'
complete -c bit -n '__fish_bit_ai_using_subcommand revert' -l skip -d 'Skip current patch'
complete -c bit -n '__fish_bit_ai_using_subcommand revert' -f -a '(__fish_bit_refs)'

complete -c bit -n '__fish_bit_using_command cherry-pick' -s e -l edit -d 'Edit message'
complete -c bit -n '__fish_bit_using_command cherry-pick' -s n -l no-commit -d 'Do not commit'
complete -c bit -n '__fish_bit_using_command cherry-pick' -s m -l mainline -r -d 'Mainline parent'
complete -c bit -n '__fish_bit_using_command cherry-pick' -l abort -d 'Abort cherry-pick'
complete -c bit -n '__fish_bit_using_command cherry-pick' -l continue -d 'Continue cherry-pick'
complete -c bit -n '__fish_bit_using_command cherry-pick' -l quit -d 'Quit cherry-pick'
complete -c bit -n '__fish_bit_using_command cherry-pick' -l skip -d 'Skip current patch'
complete -c bit -n '__fish_bit_using_command cherry-pick' -f -a '(__fish_bit_refs)'

complete -c bit -n '__fish_bit_using_command reset' -l soft -d 'Soft reset'
complete -c bit -n '__fish_bit_using_command reset' -l mixed -d 'Mixed reset'
complete -c bit -n '__fish_bit_using_command reset' -l hard -d 'Hard reset'
complete -c bit -n '__fish_bit_using_command reset' -l merge -d 'Merge reset'
complete -c bit -n '__fish_bit_using_command reset' -l keep -d 'Keep reset'
complete -c bit -n '__fish_bit_using_command reset' -s q -l quiet -d 'Quiet'
complete -c bit -n '__fish_bit_using_command reset' -f -a '(__fish_bit_refs)'

complete -c bit -n '__fish_bit_using_command log' -l oneline -d 'One line per commit'
complete -c bit -n '__fish_bit_using_command log' -l graph -d 'Show graph'
complete -c bit -n '__fish_bit_using_command log' -l all -d 'Show all refs'
complete -c bit -n '__fish_bit_using_command log' -l stat -d 'Show diffstat'
complete -c bit -n '__fish_bit_using_command log' -s p -l patch -d 'Show patch'
complete -c bit -n '__fish_bit_using_command log' -l format -r -d 'Format'
complete -c bit -n '__fish_bit_using_command log' -l pretty -r -d 'Pretty format'
complete -c bit -n '__fish_bit_using_command log' -l abbrev-commit -d 'Abbreviate commit'
complete -c bit -n '__fish_bit_using_command log' -l no-abbrev-commit -d 'Do not abbreviate commit'
complete -c bit -n '__fish_bit_using_command log' -l decorate -d 'Show decorations'
complete -c bit -n '__fish_bit_using_command log' -l no-decorate -d 'Hide decorations'
complete -c bit -n '__fish_bit_using_command log' -s n -l max-count -r -d 'Limit count'
complete -c bit -n '__fish_bit_using_command log' -l since -r -d 'Since date'
complete -c bit -n '__fish_bit_using_command log' -l until -r -d 'Until date'
complete -c bit -n '__fish_bit_using_command log' -l after -r -d 'After date'
complete -c bit -n '__fish_bit_using_command log' -l before -r -d 'Before date'
complete -c bit -n '__fish_bit_using_command log' -l author -r -d 'Author pattern'
complete -c bit -n '__fish_bit_using_command log' -l grep -r -d 'Grep pattern'
complete -c bit -n '__fish_bit_using_command log' -l first-parent -d 'Follow first parent only'
complete -c bit -n '__fish_bit_using_command log' -l merges -d 'Show only merges'
complete -c bit -n '__fish_bit_using_command log' -l no-merges -d 'Hide merges'
complete -c bit -n '__fish_bit_using_command log' -l reverse -d 'Reverse order'
complete -c bit -n '__fish_bit_using_command log' -l topo-order -d 'Topological order'
complete -c bit -n '__fish_bit_using_command log' -l date-order -d 'Date order'
complete -c bit -n '__fish_bit_using_command log' -f -a '(__fish_bit_refs)'

complete -c bit -n '__fish_bit_using_command diff' -l stat -d 'Show diffstat'
complete -c bit -n '__fish_bit_using_command diff' -l numstat -d 'Show numeric diffstat'
complete -c bit -n '__fish_bit_using_command diff' -l shortstat -d 'Show shortstat'
complete -c bit -n '__fish_bit_using_command diff' -l name-only -d 'Show names only'
complete -c bit -n '__fish_bit_using_command diff' -l name-status -d 'Show name and status'
complete -c bit -n '__fish_bit_using_command diff' -l cached -d 'Show staged changes'
complete -c bit -n '__fish_bit_using_command diff' -l staged -d 'Show staged changes'
complete -c bit -n '__fish_bit_using_command diff' -l no-index -d 'Compare files outside repo'
complete -c bit -n '__fish_bit_using_command diff' -s p -l patch -d 'Show patch'
complete -c bit -n '__fish_bit_using_command diff' -l raw -d 'Show raw diff'
complete -c bit -n '__fish_bit_using_command diff' -l diff-filter -r -d 'Diff filter'
complete -c bit -n '__fish_bit_using_command diff' -s M -l find-renames -d 'Detect renames'
complete -c bit -n '__fish_bit_using_command diff' -s C -l find-copies -d 'Detect copies'
complete -c bit -n '__fish_bit_using_command diff' -l word-diff -d 'Show word diff'
complete -c bit -n '__fish_bit_using_command diff' -l color -d 'Show color'
complete -c bit -n '__fish_bit_using_command diff' -l no-color -d 'Hide color'
complete -c bit -n '__fish_bit_using_command diff' -s U -l unified -r -d 'Context lines'
complete -c bit -n '__fish_bit_using_command diff' -f -a '(__fish_bit_refs)'

complete -c bit -n '__fish_bit_using_command show' -l stat -d 'Show diffstat'
complete -c bit -n '__fish_bit_using_command show' -l format -r -d 'Format'
complete -c bit -n '__fish_bit_using_command show' -l pretty -r -d 'Pretty format'
complete -c bit -n '__fish_bit_using_command show' -l oneline -d 'One line'
complete -c bit -n '__fish_bit_using_command show' -s p -l patch -d 'Show patch'
complete -c bit -n '__fish_bit_using_command show' -l raw -d 'Show raw'
complete -c bit -n '__fish_bit_using_command show' -l name-only -d 'Names only'
complete -c bit -n '__fish_bit_using_command show' -l name-status -d 'Name and status'
complete -c bit -n '__fish_bit_using_command show' -l abbrev-commit -d 'Abbreviate commit'
complete -c bit -n '__fish_bit_using_command show' -l no-abbrev-commit -d 'Do not abbreviate commit'
complete -c bit -n '__fish_bit_using_command show' -f -a '(__fish_bit_refs)'

complete -c bit -n '__fish_bit_using_command add' -s A -l all -d 'Add all files'
complete -c bit -n '__fish_bit_using_command add' -s u -l update -d 'Update tracked files'
complete -c bit -n '__fish_bit_using_command add' -s n -l dry-run -d 'Dry run'
complete -c bit -n '__fish_bit_using_command add' -s v -l verbose -d 'Verbose'
complete -c bit -n '__fish_bit_using_command add' -s f -l force -d 'Force add'
complete -c bit -n '__fish_bit_using_command add' -s p -l patch -d 'Interactive patch'
complete -c bit -n '__fish_bit_using_command add' -s N -l intent-to-add -d 'Intent to add'
complete -c bit -n '__fish_bit_using_command add' -F

complete -c bit -n '__fish_bit_using_command commit' -s m -l message -r -d 'Commit message'
complete -c bit -n '__fish_bit_using_command commit' -s a -l all -d 'Commit all modified files'
complete -c bit -n '__fish_bit_using_command commit' -l amend -d 'Amend last commit'
complete -c bit -n '__fish_bit_using_command commit' -l no-edit -d 'Use existing message'
complete -c bit -n '__fish_bit_using_command commit' -s e -l edit -d 'Edit message'
complete -c bit -n '__fish_bit_using_command commit' -l allow-empty -d 'Allow empty commit'
complete -c bit -n '__fish_bit_using_command commit' -l allow-empty-message -d 'Allow empty message'
complete -c bit -n '__fish_bit_using_command commit' -l author -r -d 'Author'
complete -c bit -n '__fish_bit_using_command commit' -l date -r -d 'Date'
complete -c bit -n '__fish_bit_using_command commit' -s s -l signoff -d 'Add Signed-off-by'
complete -c bit -n '__fish_bit_using_command commit' -l dry-run -d 'Dry run'
complete -c bit -n '__fish_bit_using_command commit' -s v -l verbose -d 'Verbose'
complete -c bit -n '__fish_bit_using_command commit' -F

complete -c bit -n '__fish_bit_using_command status' -s s -l short -d 'Short format'
complete -c bit -n '__fish_bit_using_command status' -s b -l branch -d 'Show branch info'
complete -c bit -n '__fish_bit_using_command status' -l porcelain -d 'Machine format'
complete -c bit -n '__fish_bit_using_command status' -l long -d 'Long format'
complete -c bit -n '__fish_bit_using_command status' -s u -l untracked-files -d 'Show untracked'
complete -c bit -n '__fish_bit_using_command status' -l ignored -d 'Show ignored'
complete -c bit -n '__fish_bit_using_command status' -s z -d 'NUL terminated'
complete -c bit -n '__fish_bit_using_command status' -F

complete -c bit -n '__fish_bit_using_command push' -l all -d 'Push all branches'
complete -c bit -n '__fish_bit_using_command push' -l tags -d 'Push tags'
complete -c bit -n '__fish_bit_using_command push' -s f -l force -d 'Force push'
complete -c bit -n '__fish_bit_using_command push' -l delete -d 'Delete remote branch'
complete -c bit -n '__fish_bit_using_command push' -l prune -d 'Prune remote branches'
complete -c bit -n '__fish_bit_using_command push' -s u -l set-upstream -d 'Set upstream'
complete -c bit -n '__fish_bit_using_command push' -s n -l dry-run -d 'Dry run'
complete -c bit -n '__fish_bit_using_command push' -s v -l verbose -d 'Verbose'
complete -c bit -n '__fish_bit_using_command push' -l no-verify -d 'Skip pre-push hook'
complete -c bit -n '__fish_bit_using_command push' -f -a '(__fish_bit_remotes)'
complete -c bit -n '__fish_bit_using_command push' -f -a '(__fish_bit_refs)'

complete -c bit -n '__fish_bit_using_command pull' -l rebase -d 'Rebase on pull'
complete -c bit -n '__fish_bit_using_command pull' -l no-rebase -d 'Merge on pull'
complete -c bit -n '__fish_bit_using_command pull' -l ff -d 'Fast-forward if possible'
complete -c bit -n '__fish_bit_using_command pull' -l no-ff -d 'Create merge commit'
complete -c bit -n '__fish_bit_using_command pull' -l ff-only -d 'Fast-forward only'
complete -c bit -n '__fish_bit_using_command pull' -l stat -d 'Show diffstat'
complete -c bit -n '__fish_bit_using_command pull' -l no-stat -d 'Hide diffstat'
complete -c bit -n '__fish_bit_using_command pull' -l squash -d 'Squash commits'
complete -c bit -n '__fish_bit_using_command pull' -l no-squash -d 'Do not squash'
complete -c bit -n '__fish_bit_using_command pull' -l all -d 'Fetch all remotes'
complete -c bit -n '__fish_bit_using_command pull' -l tags -d 'Fetch tags'
complete -c bit -n '__fish_bit_using_command pull' -l prune -d 'Prune remote branches'
complete -c bit -n '__fish_bit_using_command pull' -s v -l verbose -d 'Verbose'
complete -c bit -n '__fish_bit_using_command pull' -s q -l quiet -d 'Quiet'
complete -c bit -n '__fish_bit_using_command pull' -f -a '(__fish_bit_remotes)'
complete -c bit -n '__fish_bit_using_command pull' -f -a '(__fish_bit_refs)'

complete -c bit -n '__fish_bit_using_command fetch' -l all -d 'Fetch all remotes'
complete -c bit -n '__fish_bit_using_command fetch' -l tags -d 'Fetch tags'
complete -c bit -n '__fish_bit_using_command fetch' -l prune -d 'Prune deleted refs'
complete -c bit -n '__fish_bit_using_command fetch' -s f -l force -d 'Force update'
complete -c bit -n '__fish_bit_using_command fetch' -l depth -r -d 'Depth'
complete -c bit -n '__fish_bit_using_command fetch' -l shallow-since -r -d 'Shallow since'
complete -c bit -n '__fish_bit_using_command fetch' -l shallow-exclude -r -d 'Shallow exclude'
complete -c bit -n '__fish_bit_using_command fetch' -s n -l dry-run -d 'Dry run'
complete -c bit -n '__fish_bit_using_command fetch' -s v -l verbose -d 'Verbose'
complete -c bit -n '__fish_bit_using_command fetch' -s q -l quiet -d 'Quiet'
complete -c bit -n '__fish_bit_using_command fetch' -f -a '(__fish_bit_remotes)'

complete -c bit -n '__fish_bit_using_command remote' -f -a '$__bit_remote_subcommands'
complete -c bit -n '__fish_bit_using_command stash' -f -a '$__bit_stash_subcommands'

complete -c bit -n '__fish_bit_using_command tag' -s a -l annotate -d 'Annotated tag'
complete -c bit -n '__fish_bit_using_command tag' -s d -l delete -d 'Delete tag'
complete -c bit -n '__fish_bit_using_command tag' -s l -l list -d 'List tags'
complete -c bit -n '__fish_bit_using_command tag' -s f -l force -d 'Force'
complete -c bit -n '__fish_bit_using_command tag' -s m -l message -r -d 'Tag message'
complete -c bit -n '__fish_bit_using_command tag' -s v -l verify -d 'Verify tag'
complete -c bit -n '__fish_bit_using_command tag' -s n -r -d 'Show annotation lines'
complete -c bit -n '__fish_bit_using_command tag' -l sort -r -d 'Sort key'
complete -c bit -n '__fish_bit_using_command tag' -l contains -r -a '(__fish_bit_refs)' -d 'Tags containing commit'
complete -c bit -n '__fish_bit_using_command tag' -l no-contains -r -a '(__fish_bit_refs)' -d 'Tags not containing commit'
complete -c bit -n '__fish_bit_using_command tag' -l merged -r -a '(__fish_bit_refs)' -d 'Merged tags'
complete -c bit -n '__fish_bit_using_command tag' -l no-merged -r -a '(__fish_bit_refs)' -d 'Unmerged tags'
complete -c bit -n '__fish_bit_using_command tag' -l points-at -r -a '(__fish_bit_refs)' -d 'Tags pointing at object'
complete -c bit -n '__fish_bit_using_command tag' -f -a '(__fish_bit_tags)'

complete -c bit -n '__fish_bit_using_command rm' -s f -l force -d 'Force removal'
complete -c bit -n '__fish_bit_using_command rm' -s n -l dry-run -d 'Dry run'
complete -c bit -n '__fish_bit_using_command rm' -s r -d 'Recursive'
complete -c bit -n '__fish_bit_using_command rm' -l cached -d 'Only remove from index'
complete -c bit -n '__fish_bit_using_command rm' -s q -l quiet -d 'Quiet'
complete -c bit -n '__fish_bit_using_command rm' -F

complete -c bit -n '__fish_bit_using_command mv' -s f -l force -d 'Force move'
complete -c bit -n '__fish_bit_using_command mv' -s n -l dry-run -d 'Dry run'
complete -c bit -n '__fish_bit_using_command mv' -s v -l verbose -d 'Verbose'
complete -c bit -n '__fish_bit_using_command mv' -s k -d 'Skip errors'
complete -c bit -n '__fish_bit_using_command mv' -F

complete -c bit -n '__fish_bit_using_command config' -l global -d 'Use global config'
complete -c bit -n '__fish_bit_using_command config' -l system -d 'Use system config'
complete -c bit -n '__fish_bit_using_command config' -l local -d 'Use local config'
complete -c bit -n '__fish_bit_using_command config' -l file -r -d 'Config file'
complete -c bit -n '__fish_bit_using_command config' -s l -l list -d 'List all'
complete -c bit -n '__fish_bit_using_command config' -l get -r -d 'Get value'
complete -c bit -n '__fish_bit_using_command config' -l get-all -r -d 'Get all values'
complete -c bit -n '__fish_bit_using_command config' -l unset -r -d 'Unset value'
complete -c bit -n '__fish_bit_using_command config' -l unset-all -r -d 'Unset all values'
complete -c bit -n '__fish_bit_using_command config' -s e -l edit -d 'Edit config'
complete -c bit -n '__fish_bit_using_command config' -l add -r -d 'Add value'
complete -c bit -n '__fish_bit_using_command config' -l replace-all -r -d 'Replace all values'

complete -c bit -n '__fish_bit_using_command clone' -l bare -d 'Create bare repo'
complete -c bit -n '__fish_bit_using_command clone' -l mirror -d 'Mirror repo'
complete -c bit -n '__fish_bit_using_command clone' -l depth -r -d 'Depth'
complete -c bit -n '__fish_bit_using_command clone' -l single-branch -d 'Single branch'
complete -c bit -n '__fish_bit_using_command clone' -l no-single-branch -d 'Fetch all branches'
complete -c bit -n '__fish_bit_using_command clone' -s b -l branch -r -d 'Checkout branch'
complete -c bit -n '__fish_bit_using_command clone' -l recursive -d 'Clone submodules'
complete -c bit -n '__fish_bit_using_command clone' -l recurse-submodules -d 'Clone submodules'
complete -c bit -n '__fish_bit_using_command clone' -l shallow-submodules -d 'Shallow submodules'
complete -c bit -n '__fish_bit_using_command clone' -l no-tags -d 'Do not fetch tags'
complete -c bit -n '__fish_bit_using_command clone' -l filter -r -d 'Partial clone filter'
complete -c bit -n '__fish_bit_using_command clone' -l sparse -d 'Enable sparse checkout'
complete -c bit -n '__fish_bit_using_command clone' -s q -l quiet -d 'Quiet'
complete -c bit -n '__fish_bit_using_command clone' -s v -l verbose -d 'Verbose'
complete -c bit -n '__fish_bit_using_command clone' -l skip-hooks -d 'Skip hooks'

complete -c bit -n '__fish_bit_using_command init' -l bare -d 'Create bare repo'
complete -c bit -n '__fish_bit_using_command init' -l template -r -d 'Template dir'
complete -c bit -n '__fish_bit_using_command init' -l separate-git-dir -r -d 'Git dir'
complete -c bit -n '__fish_bit_using_command init' -s b -l initial-branch -r -d 'Initial branch'
complete -c bit -n '__fish_bit_using_command init' -l shared -r -d 'Sharing mode'
complete -c bit -n '__fish_bit_using_command init' -s q -l quiet -d 'Quiet'

complete -c bit -n '__fish_bit_using_command workspace ws' -f -a '$__bit_workspace_subcommands'
complete -c bit -n '__fish_bit_using_command workspace ws' -s m -l message -r -d 'Commit message'
complete -c bit -n '__fish_bit_using_command workspace ws' -l allow-empty -d 'Allow empty commit'
complete -c bit -n '__fish_bit_using_command workspace ws' -l resume -r -d 'Resume transaction id'
complete -c bit -n '__fish_bit_using_command workspace ws' -l affected -d 'Run only affected closure'
complete -c bit -n '__fish_bit_using_command workspace ws' -l format -r -d 'Export format'

complete -c bit -n '__fish_bit_using_command clean' -s d -d 'Remove directories'
complete -c bit -n '__fish_bit_using_command clean' -s f -l force -d 'Force'
complete -c bit -n '__fish_bit_using_command clean' -s n -l dry-run -d 'Dry run'
complete -c bit -n '__fish_bit_using_command clean' -s q -l quiet -d 'Quiet'
complete -c bit -n '__fish_bit_using_command clean' -s x -d 'Remove ignored files too'
complete -c bit -n '__fish_bit_using_command clean' -s X -d 'Remove only ignored files'
complete -c bit -n '__fish_bit_using_command clean' -s e -l exclude -r -d 'Exclude pattern'
complete -c bit -n '__fish_bit_using_command clean' -F
