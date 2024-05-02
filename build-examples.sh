#!/usr/bin/env bash
# build projects in directory ./examples

LIBCURL=$(lake update | grep 'path to libcurl' | awk '{ print $4 }')

if [ ! -f "${LIBCURL}" ]; then
    echo "libcurl not found: ${LIBCURL}"
    exit 1
fi

lake build

for dir in $(find examples/ -mindepth 1 -maxdepth 1 -type d); do 
    echo "dir ${dir}" \
		&& pushd "${dir}" \
		&& rm -rf .lake \
		&& lake -KlibCurl=${LIBCURL} update \
		&& lake build \
		&& popd;
done
