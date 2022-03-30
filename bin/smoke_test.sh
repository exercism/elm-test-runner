#!/bin/sh

set -e # Make script exit when a command fail.
set -u # Exit on usage of undeclared variable.
# set -x # Trace what gets executed.
set -o pipefail # Catch failures in pipes.

for solution in test_data/*/* ; do
  echo $solution
  slug=$(basename $(dirname $solution))
  solution=$(realpath $solution)
  # run tests
  bin/run.sh $slug $solution $solution > /dev/null
  # check result
  bin/check_files.sh $solution
done

echo "Smoke test finished"
