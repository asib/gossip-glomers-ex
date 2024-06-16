#!/bin/bash
set -euxo pipefail

trap "exit" INT

cd /Users/jfent/Desktop/gossip-glomers-ex
if [ -e "out.log" ]; then
  rm "out.log"
fi

mix compile
../maelstrom/maelstrom test --bin ./execute.sh $@
