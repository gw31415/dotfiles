function __fishify_executable --description "Check if the given commands are executable and print the missing ones"
    set -l missing 0
    for cmd in $argv
        if not command -qs -- "$cmd"
            set missing 1
            echo "$cmd"
        end
    end
    return $missing
end

function __fishify_syntax_error --description "Validate fish syntax and print parser errors without executing it"
    set -l source $argv[1]

    if test (count $argv) -ne 1
        echo "Usage: __fishify_syntax_error '<fish source>'" >&2
        return 2
    end

    fish --no-execute -c "$source" 2>&1 >/dev/null
end

function __fishify_call_openai --description "Call the OpenAI Responses API with the provided JSON payload"
    set -l payload $argv[1]

    command curl -sS https://api.openai.com/v1/responses \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$payload"
end

function fishify --description "Generate a valid fish command from natural language"
    if not set -q OPENAI_API_KEY
        echo "OPENAI_API_KEY is not set" >&2
        return 1
    end

    if not type -q jq
        echo "jq is required" >&2
        return 1
    end

    if test (count $argv) -ne 1
        echo "Usage: fishify '<request>'" >&2
        return 2
    end

    set -l request $argv[1]
    set request (string trim -- "$request")
    if test -z "$request"
        echo "Request must not be empty" >&2
        return 2
    end

    set -l model gpt-5.4-nano
    if set -q OPENAI_FISH_MODEL
        set model $OPENAI_FISH_MODEL
    end

    set -l system_prompt "You convert a user's intent into exactly one fish command or compact fish snippet. Return only fish code that is valid fish syntax. Do not include markdown, explanations, comments, surrounding quotes, or code fences. Prefer the smallest direct command that solves the request. Avoid building script-like solutions with temporary variables, multiple independent steps, or unnecessary ceremony. Use fish syntax, not POSIX/bash/zsh syntax. In particular, do not use parameter expansions like \${var}, \${var:r}, or shell features that fish does not support. You may return multiple lines only when that improves readability for a small amount of control flow such as if, switch, or for. Do not turn the answer into a script with multiple steps, helper variables, repeated state, or elaborate control flow unless the user explicitly asks for that. If the request is ambiguous, make the smallest reasonable assumption and still return one command or snippet. Before using any external executable in the final code, call the __fishify_executable tool with every external command you plan to use. Use only fish builtins, fish keywords, or external executables confirmed available by that tool."
    set -l validation_feedback ""
    set -l last_candidate ""
    set -l attempt 1
    set -l tools_json '[
        {
            "type": "function",
            "name": "__fishify_executable",
            "description": "Check whether external executables are available in the current shell environment before you use them in the final fish command. Call this before using any non-builtin command. Returns the missing command names.",
            "parameters": {
                "type": "object",
                "properties": {
                    "commands": {
                        "type": "array",
                        "items": {
                            "type": "string"
                        },
                        "description": "External executable names to verify, without arguments."
                    }
                },
                "required": ["commands"],
                "additionalProperties": false
            },
            "strict": true
        }
    ]'

    while test $attempt -le 3
        set -l input_json (command jq -cn \
            --arg system_prompt "$system_prompt" \
            --arg request "$request" \
            --arg validation_feedback "$validation_feedback" \
            '[
                {role: "system", content: $system_prompt},
                {role: "user", content: $request}
            ] + (
                if $validation_feedback != "" then
                    [{role: "system", content: $validation_feedback}]
                else
                    []
                end
            )')
        set -l response ""
        set -l resolved 0

        while test $resolved -eq 0
            set -l payload (command jq -n \
            --arg model "$model" \
            --argjson input "$input_json" \
            --argjson tools "$tools_json" \
            '{
                model: $model,
                input: $input,
                tools: $tools,
                parallel_tool_calls: false,
                text: {
                    format: {
                        type: "json_schema",
                        name: "fish_command",
                        schema: {
                            type: "object",
                            properties: {
                                command: {type: "string"}
                            },
                            required: ["command"],
                            additionalProperties: false
                        },
                        strict: true
                    }
                }
            }')

            set response (__fishify_call_openai "$payload" | string collect)
            set -l curl_status $status

            if test $curl_status -ne 0
                echo "OpenAI API request failed" >&2
                return $curl_status
            end

            set -l api_error (printf '%s\n' "$response" | command jq -er '.error.message // empty' 2>/dev/null)
            if test $status -eq 0 -a -n "$api_error"
                echo "$api_error" >&2
                return 1
            end

            set -l function_calls (printf '%s\n' "$response" | command jq -c '.output[]? | select(.type == "function_call")' 2>/dev/null)
            if test $status -ne 0
                echo "Could not parse the OpenAI response" >&2
                return 1
            end

            if test (count $function_calls) -eq 0
                set resolved 1
                break
            end

            set -l response_output_json (printf '%s\n' "$response" | command jq -c '.output')
            if test $status -ne 0
                echo "Could not parse tool calls from the OpenAI response" >&2
                return 1
            end

            set input_json (command jq -cn \
                --argjson existing "$input_json" \
                --argjson additions "$response_output_json" \
                '$existing + $additions')

            set -l tool_outputs_json '[]'
            for call in $function_calls
                set -l tool_name (printf '%s\n' "$call" | command jq -r '.name')
                set -l call_id (printf '%s\n' "$call" | command jq -r '.call_id')
                set -l arguments_json (printf '%s\n' "$call" | command jq -c '.arguments | fromjson')

                if test "$tool_name" = __fishify_executable
                    set -l commands (printf '%s\n' "$arguments_json" | command jq -r '.commands[]')
                    set -l missing (__fishify_executable $commands)
                    set -l tool_output (command jq -cn \
                        --argjson commands "$(printf '%s\n' "$arguments_json" | command jq -c '.commands')" \
                        --argjson missing "$(printf '%s\n' "$missing" | command jq -R -s 'split("\n") | map(select(length > 0))')" \
                        '{
                            ok: ($missing | length == 0),
                            checked: $commands,
                            missing: $missing
                        }')
                else
                    set -l tool_output (command jq -cn --arg name "$tool_name" '{ok: false, error: ("Unknown tool: " + $name)}')
                end

                set tool_outputs_json (command jq -cn \
                    --argjson existing "$tool_outputs_json" \
                    --arg call_id "$call_id" \
                    --arg output "$tool_output" \
                    '$existing + [{
                        type: "function_call_output",
                        call_id: $call_id,
                        output: $output
                    }]')
            end

            set input_json (command jq -cn \
                --argjson existing "$input_json" \
                --argjson additions "$tool_outputs_json" \
                '$existing + $additions')
        end

        set -l candidate (printf '%s\n' "$response" | command jq -er '([.output[]?.content[]? | select(.type == "output_text") | .text][0] // .output_text) | fromjson | .command' 2>/dev/null | string collect)
        if test $status -ne 0 -o -z "$candidate"
            echo "Could not parse a command from the OpenAI response" >&2
            return 1
        end

        set candidate (printf '%s' "$candidate" | string trim | string collect)
        set last_candidate $candidate

        set -l syntax_error (__fishify_syntax_error "$candidate" | string collect)
        if test $status -eq 0
            printf '%s\n' "$candidate"
            return 0
        end

        set validation_feedback "The previous candidate was not valid fish syntax. Return a different command that is valid fish syntax. Invalid candidate: $candidate

fish parser error:
$syntax_error"
        set attempt (math $attempt + 1)
    end

    echo "Model did not return valid fish syntax after 3 attempts" >&2
    if test -n "$last_candidate"
        echo "Last candidate: $last_candidate" >&2
    end
    return 1
end
