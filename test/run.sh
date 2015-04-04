#!/bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

# Run only the unit tests that do not rely on any external LDAP
# servers (i.e. integration tests)

UNIT_TESTS="misc filter configuration control"

cd $ROOT_DIR

for ut in $UNIT_TESTS;
do
   dart --enable-checked-mode $ROOT_DIR/test/"$ut"_test.dart
done 