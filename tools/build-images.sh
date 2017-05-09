#!/bin/bash
# vi: expandtab sw=4 ts=4

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2017, Joyent, Inc.
#

#
# Build the triton-origin images per the given build info and images config.
#

if [[ -n "$TRACE" ]]; then
    if [[ -t 1 ]]; then
        export PS4='\033[90m[\D{%FT%TZ}] ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }\033[39m'
    else
        export PS4='[\D{%FT%TZ}] ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    fi
    set -o xtrace
fi
set -o errexit
set -o pipefail


TOP=$(cd $(dirname $0)/../ > /dev/null; pwd)
SCRIPT="$(basename $0)"

export PATH="${TOP}/node_modules/.bin:${PATH}"


# ---- support functions

function fatal {
    if [[ -n "$1" ]]; then
        echo "$SCRIPT: error: $1" >&2
    fi
    exit 1
}

function usage() {
    echo "Usage:"
    echo "  $SCRIPT -i IMAGES-CONFIG-FILE -b BUILDINFO-FILE"
    echo ""
    echo "Options:"
    echo "  -h       Print this help and exit."
    echo "  -i FILE  images config file, typically ./images.json"
    echo "  -b FILE  buildinfo file, typically ./build/buildinfo.json"
}

function usageErr() {
    if [[ -n "$1" ]]; then
        echo "$SCRIPT: error: $1" >&2
        echo ""
    fi
    usage
    fatal
}


# ---- mainline

imagesFile=
buildinfoFile=
while getopts hi:b: opt; do
    case $opt in
    h)
        usage
        exit 0
        ;;
    i)
        [[ -n "$OPTARG" ]] && imagesFile="$OPTARG"
        ;;
    b)
        [[ -n "$OPTARG" ]] && buildinfoFile="$OPTARG"
        ;;
    *)
        usage
        exit 1
        ;;
    esac
done
shift $(($OPTIND - 1))

[[ -n "$imagesFile" ]] || usageErr "missing '-i FILE' option"
[[ -f "$imagesFile" ]] || usageErr "images file does not exist: $imagesFile"
json -qnf "$imagesFile" || fatal "'$imagesFile' is not valid JSON"
[[ -n "$buildinfoFile" ]] || usageErr "missing '-b FILE' option"
[[ -f "$buildinfoFile" ]] || usageErr "buildinfo file does not exist: $buildinfoFile"

imagesConfig=$(cat $imagesFile)
numImages=$(echo "$imagesConfig" | json length)
for (( i=0; i<$numImages; i++ ))
do
    echo ""
    imageConfig=$(echo "$imagesConfig" | json $i)
    $TOP/tools/build-image.sh "$imageConfig" "$buildinfoFile"
done
