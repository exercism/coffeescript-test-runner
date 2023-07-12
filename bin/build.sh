#!/usr/bin/env bash

set -euo pipefail

echo "Building"
npx coffee -c ./bin/results.coffee
