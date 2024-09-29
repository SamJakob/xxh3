#!/bin/sh

set -exu

if [ -d ./coverage ]; then
  echo "Coverage directory exists. Removing..."
  rm -r ./coverage
fi

# Run dart tests with coverage
dart run test --coverage=./coverage

# Ensure coverage package is activated.
dart pub global activate coverage

# Format lib/ coverage data in lcov format.
dart pub global run coverage:format_coverage --report-on=lib --lcov -o ./coverage/lcov.info -i ./coverage

# Generate LCOV report.
genhtml -o ./coverage/report ./coverage/lcov.info
