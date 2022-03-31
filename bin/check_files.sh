#!/bin/sh
#
#  This script is called by bin/smoke_test.sh
#
#  It checks that for a given exercise path (given as argument)
#    1. The test runner created an output file
#    2. There is a reference file available for comparison
#    3. Both files are identical
#
#  Otherwise, it fails with an error message.
#

set -euo pipefail

exercise=$1

function installed {
  cmd=$(command -v "${1}")

  [[ -n "${cmd}" ]] && [[ -f "${cmd}" ]]
  return ${?}
}

function die {
  >&2 echo "Fatal: ${@}"
  exit 1
}

function main {
  if [[ ! -f "${exercise}/expected_results.json" ]]; then
    echo "🔥 ${exercise}: expected expected_results.json to exist 🔥"
    exit 1
  fi

  if [[ ! -f "${exercise}/results.json" ]]; then
    echo "🔥 ${exercise}: expected results.json to exist on successful run 🔥"
    exit 1
  fi

  jq -S . ${exercise}/expected_results.json > /tmp/expected.json
  jq -S . ${exercise}/results.json > /tmp/actual.json
  if ! diff /tmp/expected.json /tmp/actual.json ;then
    echo "🔥 ${exercise}: expected ${exercise}/results.json to equal ${exercise}/expected_results.json on successful run 🔥"
    exit 1
  fi

  echo "🏁 ${exercise}: expected files present and correct after successful run 🏁"
}

# Check for all required dependencies
for dep in diff jq; do
  installed "${dep}" || die "Missing '${dep}'"
done

main "$@"; exit
