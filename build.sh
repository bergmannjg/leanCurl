#!/usr/bin/env bash

lake build

for dir in $(find examples/ -mindepth 1 -maxdepth 1 -type d); do 
    pushd "${dir}" && rm -rf build && lake build && popd;
done
