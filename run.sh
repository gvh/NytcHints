#!/bin/zsh
# Build nytcHints (release) and run it, passing through any arguments.
#   ./run.sh mash              # Mashable, today
#   ./run.sh cnet 2026-09-18   # CNET, a specific date
#   ./run.sh tech              # TechRadar, today
set -e

cd "${0:A:h}"

swift build -c release -q
exec .build/release/nytcHints "$@"
