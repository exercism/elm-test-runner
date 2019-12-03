# Example:
# ./run.sh pangram ~/Exercism/elm/pangram .

pushd $2

echo "Running tests"
elm-test --report junit > junit.xml

popd

# Convert JUnit report to results.json
# At some future date, this script should be replaced
# with one provided by exercism/automated-tests
echo "Converting Junit output to exercism output"
python process_results.py $2/junit.xml $3/results.json