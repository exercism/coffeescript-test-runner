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
capture_file="${output_dir}/capture"
results_file="${output_dir}/results.json"

# Create the output directory if it doesn't exist
mkdir -p "${output_dir}"

echo "${slug}: testing..."

cp "${tests_file}" "${original_tests_file}"

# Enable all pending tests
sed -i 's/xit/it/g' "${tests_file}"

# Run the tests for the provided implementation file and redirect stdout and
# stderr to capture it
test_output=$(jasmine-node --color --junitreport --output ${output_dir} --coffee "${tests_file}" &> "${capture_file}")
file=$(find ${output_dir} -type f -name "*.xml")
node bin/results.js "${file}" "${output_dir}" "${capture_file}"

mv -f "${original_tests_file}" "${tests_file}"
