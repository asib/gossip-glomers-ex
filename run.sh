#!/bin/bash
set -euxo pipefail

trap "exit" INT

cd /Users/jfent/Desktop/gossip-glomers-ex
#MIX_ENV=prod mix release --quiet --overwrite

mix compile
../maelstrom/maelstrom test --bin ./execute.sh $@
