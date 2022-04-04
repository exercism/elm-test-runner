#!/bin/sh

set -e # Make script exit when a command fail.
set -u # Exit on usage of undeclared variable.
# set -x # Trace what gets executed.
set -o pipefail # Catch failures in pipes.

for solution in test_data/*/* ; do
  slug=$(basename $(dirname $solution))
  solution=$(realpath $solution)

  # run tests
  bin/run.sh $slug $solution $solution > /dev/null

  # check result
  if [[ ! -f "${solution}/expected_results.json" ]]; then
    echo "🔥 ${solution}: expected expected_results.json to exist 🔥"
    exit 1
  fi

  if [[ ! -f "${solution}/results.json" ]]; then
    echo "🔥 ${solution}: expected results.json to exist on successful run 🔥"
    exit 1
  fi

  jq -S . ${solution}/expected_results.json > /tmp/expected.json
  jq -S . ${solution}/results.json > /tmp/actual.json
  if ! diff /tmp/expected.json /tmp/actual.json ;then
    echo "🔥 ${solution}: expected results.json to equal expected_results.json on successful run 🔥"
    exit 1
  fi

  echo "🏁 ${solution}: expected files present and correct after successful run 🏁"
done

echo "Smoke test finished"
