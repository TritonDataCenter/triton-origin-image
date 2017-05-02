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
# Publish the built images per the given build info.
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
    echo "  $SCRIPT -b BUILDINFO-FILE"
    echo ""
    echo "Options:"
    echo "  -h       Print this help and exit."
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

buildinfoFile=
while getopts hb: opt; do
    case $opt in
    h)
        usage
        exit 0
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

[[ -n "$buildinfoFile" ]] || usageErr "missing '-b FILE' option"
[[ -f "$buildinfoFile" ]] || usageErr "buildinfo file does not exist: $buildinfoFile"
json -qnf "$buildinfoFile" || fatal "'$buildinfoFile' is not valid JSON"


buildinfo=$(cat "$buildinfoFile")
tritonAccount=$(triton profile get -j | json account)
tritonKeyId=$(triton profile get -j | json keyId)
branch=$(echo "$buildinfo" | json branch)
[[ -n "$branch" ]] || fatal "buildinfo is missing 'branch'"
timestamp=$(echo "$buildinfo" | json timestamp)
[[ -n "$timestamp" ]] || fatal "buildinfo is missing 'timestamp'"
mantaUploadDir=/$tritonAccount/public/builds/triton-origin-image/$branch-$timestamp/


# Hardcoded MANTA_URL b/c can't get from CloudAPI.
export MANTA_URL=https://us-east.manta.joyent.com
export MANTA_USER=$tritonAccount
export MANTA_KEY_ID=$tritonKeyId
unset MANTA_TLS_INSECURE  # not yet supported
unset MANTA_SUBUSER  # not supported


if [[ $branch == "master" ]]; then
    channel=dev
else
    channel=experimental
fi
imgmanifests=$(mfind -t o -n '^triton-origin-.*\.imgmanifest$' $mantaUploadDir)

for imgmanifestMpath in $imgmanifests; do
    # Longer term: I'd like to support updates.joyent.com having a special
    # "import an image from files in the same Manta I use". In which case we
    # would not need to download the (largish) image file and then immediately
    # upload it again.
    #
    # For now: Download the manifest and file and `updates-imgadm import` it.
    base=$(basename $imgmanifestMpath .imgmanifest)
    imgUuid=$(json -f build/$base.imgmanifest uuid)
    imgName=$(json -f build/$base.imgmanifest name)
    imgVer=$(json -f build/$base.imgmanifest version)
    imgFileSha1=$(json -f build/$base.imgmanifest files.0.sha1)
    echo ""
    echo "Publishing image $imgUuid ($imgName@$imgVer)"
    echo "    to https://updates.joyent.com (channel '$channel')"

    # Download the bits to publish. If we already have the (large) file,
    # try to avoid re-downloading it (e.g. from a failed earlier publish
    # attempt).
    mget -o build/$base.imgmanifest $imgmanifestMpath
    if [[ -f build/$base.zfs.gz ]]; then
        currSha1=$(openssl dgst -sha1 build/$base.zfs.gz | awk '{print $NF}')
        if [[ $currSha1 != $imgFileSha1 ]]; then
            rm build/$base.zfs.gz
        fi
    fi
    if [[ ! -f build/$base.zfs.gz ]]; then
        mget -o build/$base.zfs.gz $mantaUploadDir/$base.zfs.gz
    fi

    # Publish it.
    updates-imgadm -C $channel import -m build/$base.imgmanifest -f build/$base.zfs.gz
done
