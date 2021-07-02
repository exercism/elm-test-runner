#!/bin/sh

set -e # Make script exit when a command fail.
set -u # Exit on usage of undeclared variable.
# set -x # Trace what gets executed.
set -o pipefail # Catch failures in pipes.

# Command line arguments
SLUG="$1"
INPUT_DIR="$2"
OUTPUT_DIR="$3"

# Setup a working directory
WORK_DIR=/opt/test-runner/app
cp -rp $INPUT_DIR $WORK_DIR
mkdir -p $WORK_DIR/elm-stuff && rm -rf $WORK_DIR/elm-stuff
tar xf cache.tar -C $WORK_DIR
cd $WORK_DIR

# Add bin/ to the path to make available elm and elm-test-rs.
export PATH=/opt/test-runner/bin:${PATH}

# Use the cache in .elm/ by redefining the elm home directory.
export ELM_HOME=$WORK_DIR/.elm

# Setup a proxy to fail requests faster in offline mode for the elm compiler.
# Otherwise, the elm compiler freezes for 5s before switching to offline mode.
cat <<EOT >> proxy.conf
LogLevel Error
Port 4343
Listen 127.0.0.1
MaxClients 100
StartServers 1
Filter "filter.conf"
FilterDefaultDeny Yes
EOT

touch filter.conf
export https_proxy=127.0.0.1:4343
tinyproxy -d -c proxy.conf &

# Un-skip all the skipped tests
sed -i 's/skip <|//g' tests/Tests.elm

# Temporarily disable -e mode
set +e
elm-test-rs -v --report exercism --offline > $OUTPUT_DIR/results.json 2> stderr.txt
STATUS=$?
cat stderr.txt
# elm-test-rs will exit(0) if tests pass, exit(2) if tests fail
if [ $STATUS -ne 0 ] && [ $STATUS -ne 2 ]; then
   jq -n --rawfile m stderr.txt '{version: 3, status: "error", message:$m}' > $OUTPUT_DIR/results.json
   echo "Finished with error"
   exit 0
fi

# Extract test code
cat tests/Tests.elm | node ../bin/cli.js > $OUTPUT_DIR/test_code.json 2> stderr.txt
STATUS=$?
cat stderr.txt
if [ $STATUS -ne 0 ]; then
   echo "An error occurred while extracting the test code from the test file."
   exit 0
fi
set -e

cd $OUTPUT_DIR
# Merge tests results with extracted test code.
# This rely on the fact that the order is the same in both arrays.
jq -s '[range(.[1]|length) as $i | .[0].tests[$i] + { test_code: .[1][$i].testCode }]' results.json test_code.json > concat.json
jq -s '.[0].tests = .[1] | .[0]' results.json concat.json > results_with_code.json
mv results_with_code.json results.json

echo Finished
