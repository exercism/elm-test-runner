#!/usr/bin/env bash

# Synopsis:
# Test runner for run.sh in a docker container
# Takes the same arguments as run.sh (EXCEPT THAT SOLUTION AND OUTPUT PATH ARE RELATIVE)
# Builds the Dockerfile
# Runs the docker image passing along the initial arguments

# Arguments:
# $1: exercise slug
# $2: **RELATIVE** path to solution folder (with trailing slash)
# $3: **RELATIVE** path to output directory (with trailing slash)

# Output:
# Writes the test results to a results.json file in the passed-in output directory.
# The test results are formatted according to the specifications at https://github.com/exercism/automated-tests/blob/master/docs/interface.md

# Example:
# bin/run-in-docker.sh two-fer path/to/two-fer/solution/folder/ path/to/output/directory/

set -e # Make script exit when a command fail.
set -u # Exit on usage of undeclared variable.
# set -x # Trace what gets executed.
set -o pipefail # Catch failures in pipes.

USAGE="bin/run-in-docker.sh <exercise-slug> <exercise_directory> <output_directory>"

# If arguments not provided, print usage and exit
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $USAGE"
    exit 1
fi

SLUG="$1"
# Retrieve absolute normalized paths
INPUT=$(readlink -f $2)
OUTPUT=$(readlink -f $3)

# build docker image
docker build -t elm-test-runner .

# run image passing the arguments
docker run --network none --read-only \
    --mount type=bind,src=$INPUT,dst=/solution \
    --mount type=bind,src=$OUTPUT,dst=/output \
    --mount type=bind,src=/tmp,dst=/tmp \
    elm-test-runner $SLUG /solution /output
