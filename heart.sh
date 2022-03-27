#!/usr/bin/env sh

SCRIPT_DIR=$(dirname "$0")
lua "${SCRIPT_DIR}/heart.lua" "$@"
