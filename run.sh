#!/usr/bin/env bash

# Example:
# ./run.sh pangram ~/Exercism/elm/pangram .

echo $1, $2, $3

cd $2

echo "Running tests"
# elm-test ends up on the path
elm-test --report junit > junit.xml

cd /

# Convert JUnit report to results.json
# At some future date, this script should be replaced
# with one provided by exercism/automated-tests
echo "Converting Junit output to exercism output"
python3 /opt/test-runner/bin/process_results.py $2/junit.xml $3/results.json

echo Finished
