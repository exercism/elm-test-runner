#!/usr/bin/env bash

# Example:
# bin/run.sh pangram ~/exercism/elm/pangram .

set -e # Make script exit when a command fail.
set -u # Exit on usage of undeclared variable.
# set -x # Trace what gets executed.
set -o pipefail # Catch failures in pipes.

EXERCISE_SLUG="$1"
EXERCISE_DIR=$(readlink -f $2)
OUTPUT_DIR=$(readlink -f $3)
TMP_DIR="/tmp/exercism-elm/$EXERCISE_SLUG"

# copy exercise dir content into /tmp
# since exercise dir is not supposed to be writable
echo "Copying exercise files into $TMP_DIR"
mkdir -p $TMP_DIR && rm -rf $TMP_DIR
cp -r $EXERCISE_DIR $TMP_DIR

# copy locally installed elm and elm-test to /tmp
cp -r package.json node_modules $TMP_DIR

# If we are in the test runner (read only)
# Change .elm location to tmp dir
# CONTEXT variable is set in run-in-docker.sh
if [[ $CONTEXT = test-runner ]]
then
    cp -r .elm $TMP_DIR
	ELM_HOME=$TMP_DIR/.elm
fi

# run elm tests in tmp dir
pushd $TMP_DIR > /dev/null
echo "Running tests"
npm test --silent -- --report junit > junit.xml
popd > /dev/null

# Convert JUnit report to results.json
# At some future date, this script should be replaced
# with one provided by exercism/automated-tests
echo "Converting Junit output to exercism output"
python3 process_results.py $TMP_DIR/junit.xml $OUTPUT_DIR/results.json

echo Finished
