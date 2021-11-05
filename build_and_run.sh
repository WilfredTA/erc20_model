#!/bin/bash
TEST_FILES="tests/*"
set -euo pipefail

kompile --backend haskell erc20.k --main-module ERC20 --syntax-module ERC20

for f in $TEST_FILES; do
   echo "Running test $f";
   echo "-----------------"
   krun "$f";
   echo "---------------"
done

kprove test-spec.k