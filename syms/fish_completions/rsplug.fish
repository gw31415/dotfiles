
# fish completion for rsplug
# Save as: ~/.config/fish/completions/rsplug.fish

complete -c rsplug -f

# --- Options ---
complete -c rsplug -s i -l install -d "Install plugins which are not installed yet"

# --update and --locked are mutually exclusive
complete -c rsplug -s u -l update -d "Access remote and update repositories" -n "not __fish_seen_argument -l locked"
complete -c rsplug      -l locked -d "Fix the repo version with rev in the lockfile" -n "not __fish_seen_argument -l update"

# --lockfile takes a path
complete -c rsplug -l lockfile -r -F -d "Specify the lockfile path" -n "not __fish_seen_argument -l lockfile"

complete -c rsplug -s h -l help -d 'Print help'

# --- Arguments ---
# CONFIG_FILES are glob-patterns; fish already supports globs, so we just accept files.
# (If your patterns can include ':' as a separator, users will type it explicitly.)
complete -c rsplug -a "(__fish_complete_path)" -d "Config file glob-pattern(s)"
