#!/usr/bin/env sh

run_debug() {
    lua -l conf-dev loved.lua "$@"
}

run() {
    lua loved.lua "$@" 
}

if [ -z $1 ] || [ $1 != "--debug" ]; then
    run "$@"
else
    shift
    run_debug "$@"
fi
