#!/usr/bin/env bash

# Read the .meta/config.json to get test name to task ID mapping
read_config() {
    local config_file="$1"
    if [[ -f "$config_file" ]]; then
        cat "$config_file"
    else
        echo "{}"
    fi
}

# Extract test name from test output line
extract_test_name() {
    local line="$1"
    echo "$line" | sed 's/^── Failure.*──  //' | sed 's/ ──$//' | head -1
}

# Get task_id for a test name from config
get_task_id() {
    local test_name="$1"
    local config="$2"
    echo "$config" | jq -r ".tests[] | select(.name==\"$test_name\") | .task_id" 2>/dev/null
}

# Main script
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "usage: ./bin/run.sh exercise-slug /absolute/path/to/solution/folder/ /absolute/path/to/output/directory/"
    exit 1
fi

slug="$1"
input_dir="${2%/}"
output_dir="${3%/}"
tests_file="test_${slug}.R"
results_file="${output_dir}/results.json"
config_file="${input_dir}/.meta/config.json"

mkdir -p "${output_dir}"
echo "${slug}: testing..."

pushd "${input_dir}" > /dev/null

# Run tests and capture output
test_output=$(Rscript "${tests_file}" 2>&1)
exit_code=$?

failed=$(echo "${test_output}" | grep -c -E '── (Failure|Error)')
if [[ $exit_code -eq 0 ]] && [[ ! $failed -eq 0 ]]; then
    exit_code=1
fi

popd > /dev/null

# Read config
config=$(read_config "${config_file}")

# Generate results.json based on exit code
if [[ $exit_code -eq 0 ]] && [ $failed -eq 0 ]; then
    jq -n '{version: 3, status: "pass", tests: []}' > ${results_file}
else
    # Parse test output and extract individual test results
    # For version 3, you need to create test objects with task_id
    
    sanitized_test_output=$(echo "${test_output}" | sed -E 's/🥇|🌈|🥳|🎊|😸|😀|🎉/🥇/g')
    colorized_test_output=$(echo "${sanitized_test_output}" | GREP_COLOR='01;31' grep --color=always -E -e '^── (Error|Failure).*|$')
    
    jq -n --arg output "${colorized_test_output}" --argjson config "$config" \
        '{version: 3, status: "fail", message: $output, tests: []}' > ${results_file}
fi

echo "${slug}: done"

