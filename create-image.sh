#!/bin/bash
# vi: expandtab sw=4 ts=4

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2017, Joyent, Inc.
#

export PS4='[\D{%FT%TZ}] ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
if [[ -z "$(echo "$*" | grep -- ' -h ' || true)" ]]; then
  # Try to avoid xtrace goop when print help/usage output.
  set -o xtrace
fi

TOP=$(cd $(dirname $0) > /dev/null; pwd)
SCRIPT="$(basename $0)"

export PATH="${TOP}/node_modules/triton/bin:${PATH}"

[[ -f "$TOP/package.json" ]] && pkgjson="$TOP/package.json"

function fatal {
    echo "$SCRIPT: error $1"

    cleanup 1
}

function cleanup() {
    local exit_status=${1:-$?}

    if [[ -n "$KEEP_INFRA_ON_FAILURE" ]]; then
        echo "$0: NOT cleaning up (\$KEEP_INFRA_ON_FAILURE is set)"
        exit $exit_status
    fi

    [[ -n "$name" ]] && triton instance rm $name || true
    [[ -n "$image_uuid" ]] && triton image rm -f ${image_uuid} || true

    exit $exit_status
}

function usage() {
    if [[ -n "$1" ]]; then
        echo "error: $1"
        echo ""
    fi

    echo "Usage:"
    echo "  $SCRIPT [OPTIONS] [MANTA_PATH]"
    echo ""
    echo "  -h       Print this help and exit."
    echo "  -f FILE  Use FILE for configuration."
    echo "  -p FILE  Use FILE as package.json." 
    echo ""

    exit 1
}

while getopts hf:p: opt; do
    case $opt in
    h)
        usage
        ;;
    f)
        [[ -n "$OPTARG" ]] && cfgfile="$OPTARG"
        ;;
    p)
        [[ -n "$OPTARG" ]] && pkgjson="$OPTARG"
        ;;
    \?)
        echo "Invalid flag -${opt}" >&2
        exit 1
        ;;
    esac
done

shift $(($OPTIND - 1))

[[ -n "$cfgfile" ]] || fatal "No configuration file specified, use '-f FILE'"
[[ -f "$cfgfile" ]] || fatal "Configuration file $cfgfile not found"
[[ -f "$pkgjson" ]] || fatal "No package.json file specified, use '-p FILE'"
[[ -n "$1" ]] && manta_path="$1"

image_name=$(json -f "$cfgfile" name)
image_version=$(json -f "$pkgjson" version)
image_url=$(json -f "$pkgjson" homepage)
image_desc=$(json -f "$cfgfile" desc)
image_package=$(json -f "$cfgfile" image_package)
image_origin_uuid=$(json -f "$cfgfile" origin.uuid)
image_origin_name=$(json -f "$cfgfile" origin.name)
image_origin_version=$(json -f "$cfgfile" origin.version)
pkgs="$(json -f "$cfgfile" -e 'this.pkg = this.packages.join(" ")' pkg)"

# Allow some overrides
image_name=${TRITON_IMAGE_NAME:-${image_name}}
image_version=${TRITON_IMAGE_VERSION:-${image_version}}
image_package=${TRITON_IMAGE_PACKAGE:-${image_package}}
pkgs=${TRITON_IMAGE_PKGS:=${pkgs}}

# Can specify name@version or short id to override as well
# in which case this won't actually hold a UUID
image_origin_uuid=${TRITON_IMAGE_ORIGIN:-${image_origin_uuid}}

amt=$(triton package list -H name=$image_package | wc -l)
[[ $amt -eq 0 ]] && fatal "Cannot find image package $image_package"
[[ $amt -gt 1 ]] && fatal "Image package $image_package is ambiguous"

# Only validate the UUID, name, and verison agree if the value
# hasn't been overridden
if [[ -n "$TRITON_IMAGE_NAME" ]]; then
    amt=$(triton image list -j \
        name=$image_origin_name \
        version=$image_origin_version | \
        json -c "this.id === '$image_origin_uuid'" | \
        wc -l)
    [[ $amt -ne 0 ]] || fatal "Image UUID mismatch with name and version"
fi

trap cleanup ERR

name=$(printf "triton-origin-proto-%02d\n" $((RANDOM % 100)))
script="/opt/local/bin/pkgin update"
script="${script}; /opt/local/bin/pkgin -y in $pkgs"
script="${script}; touch /.done"

triton instance create -w -n $name \
    -m "user-script=$script" \
    $image_origin_uuid $image_package \
    || fatal "Unable to create prototype instance"

ip=$(triton instance ip $name)
ssh="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "
ssh="$ssh root@$ip"
count=0

trap '' ERR
while (( count < 30 )); do
    $ssh "[[ -f /.done ]] || exit 42" > /dev/null && break

    rc=$?
    [[ $rc -ne 42 ]] && fatal "Error during ssh"

    (( count = count + 1 ))
    sleep 60
done
trap cleanup ERR

$ssh "rm /.done"

triton instance stop -w $name || fatal "Error while stopping instance $name"

image_uuid=$(triton image create -jw \
    -d "$image_desc" \
    -t '{"smartdc_service": true}' \
    --homepage "$image_url" \
    $name ${image_name} ${image_version} | json -g 1.id \
    || fatal "Unable to create image")

[[ -n "$manta_path" ]] && triton image export ${image_uuid} $manta_path

triton instance rm $name
