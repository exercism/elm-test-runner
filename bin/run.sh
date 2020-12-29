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
ls -l
ls -l elm-stuff/tests-0.19.1/

# Add bin/ to the path to make available elm and elm-test-rs.
export PATH=$WORK_DIR/bin:${PATH}

# Use the cache in .elm/ by redefining the elm home directory.
export ELM_HOME=$WORK_DIR/.elm

# Temporarily disable -e mode
set +e
elm-test-rs --connectivity offline > $OUTPUT_DIR/results.json 2> stderr.txt
STATUS=$?
ls -l elm-stuff/tests-0.19.1/
cat stderr.txt
# elm-test-rs will exit(0) if tests pass, exit(2) if tests fail
if [ $STATUS -ne 0 ] && [ $STATUS -ne 2 ]; then
   jq -n --rawfile m stderr.txt '{status: "error", message:$m}' > $OUTPUT_DIR/results.json
   echo "Finished with error"
   exit 0
fi
set -e

echo Finished
