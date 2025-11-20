#!/usr/bin/env fish

# Thanks to atusy for the idea!

set -g ___fish_using_prefix

function using
    set ___fish_using_prefix $argv ""
end

function __preprompt --on-event fish_prompt
    commandline --replace "$___fish_using_prefix"
end
