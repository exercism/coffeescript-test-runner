#!/usr/bin/env bash

# Synopsis:
# Run the test runner on a solution.

# Arguments:
# $1: exercise slug
# $2: absolute path to solution folder
# $3: absolute path to output directory

# Output:
# Writes the test results to a results.json file in the passed-in output directory.
# The test results are formatted according to the specifications at https://github.com/exercism/docs/blob/main/building/tooling/test-runners/interface.md

# Example:
# ./bin/run.sh two-fer /absolute/path/to/two-fer/solution/folder/ /absolute/path/to/output/directory/

# If any required arguments is missing, print the usage and exit
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "usage: ./bin/run.sh exercise-slug /absolute/path/to/two-fer/solution/folder/ /absolute/path/to/output/directory/"
    exit 1
fi

slug="$1"
input_dir="${2%/}"
output_dir="${3%/}"
tests_file="${input_dir}/${slug}.spec.coffee"
original_tests_file="${input_dir}/${slug}.spec.coffee.original"
results_file="${output_dir}/results.json"

# Create the output directory if it doesn't exist
mkdir -p "${output_dir}"

echo "${slug}: testing..."

cp "${tests_file}" "${original_tests_file}"

# Enable all pending tests
sed -i 's/xit/it/g' "${tests_file}"

# Run the tests for the provided implementation file and redirect stdout and
# stderr to capture it
test_output=$(npx jasmine-node --color --coffee "${tests_file}" 2>&1)
exit_code=$?
exception=$(echo "${test_output}" | grep -c 'Exception loading')

if [[ $exit_code -eq 0 ]] && [[ ! $exception -eq 0 ]]; then    
    exit_code=1
fi

mv -f "${original_tests_file}" "${tests_file}"

# Write the results.json file based on the exit code of the command that was 
# just executed that tested the implementation file
if [ $exit_code -eq 0 ]; then
    jq -n '{version: 1, status: "pass"}' > ${results_file}
else
    jq -n --arg output "${test_output}" '{version: 1, status: "fail", output: $output}' > ${results_file}
fi

echo "${slug}: done"
