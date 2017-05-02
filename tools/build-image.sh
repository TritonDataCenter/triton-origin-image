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
# Build a single triton-origin image with the given image config.
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
    cleanup 1
}

function cleanup() {
    local exit_status=${1:-$?}

    if [[ -n "$KEEP_INFRA_ON_FAILURE" ]]; then
        echo "$0: NOT cleaning up (\$KEEP_INFRA_ON_FAILURE is set)" >&2
    else
        [[ -n "$protoName" ]] && triton instance rm $protoName || true
        [[ -n "$imageUuid" ]] && triton image rm -f ${imageUuid} || true
    fi


    exit $exit_status
}

function usage() {
    echo "Usage:"
    echo "  $SCRIPT IMAGE-CONFIG-JSON BUILDINFO-FILE"
    echo ""
    echo "Options:"
    echo "  -h       Print this help and exit."
    echo ""
    echo "Environment:"
    echo "  KEEP_INFRA_ON_FAILURE=1     Set this to *not* remove the proto"
    echo "                              instance and created image on script "
    echo "                              failure. Useful for debugging."
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

while getopts h opt; do
    case $opt in
    h)
        usage
        exit 0
        ;;
    *)
        usage
        exit 1
        ;;
    esac
done
shift $(($OPTIND - 1))

imageConfig="$1"
[[ -n "$imageConfig" ]] || usageErr "missing IMAGE-CONFIG-JSON arg"
buildinfoFile="$2"
[[ -n "$buildinfoFile" ]] || usageErr "missing BUILDINFO-FILE arg"
[[ -f "$buildinfoFile" ]] || usageErr "buildinfo file does not exist: $buildinfoFile"
json -qnf "$buildinfoFile" || fatal "'$buildinfoFile' is not valid JSON"

buildinfo=$(cat "$buildinfoFile")
originUuid=$(echo "$imageConfig" | json origin.uuid)
originName=$(echo "$imageConfig" | json origin.name)
originVersion=$(echo "$imageConfig" | json origin.version)
imageName=$(echo "$imageConfig" | json namePrefix)-$originVersion
imageVersion=$(cat $TOP/package.json | json version)
imageHomepage=$(cat $TOP/package.json | json homepage)
imageDesc=$(echo "$imageConfig" | json desc)
protoMinMemoryMb=$(echo "$imageConfig" | json protoMinMemoryMb)
tritonAccount=$(triton profile get -j | json account)
tritonKeyId=$(triton profile get -j | json keyId)
branch=$(echo "$buildinfo" | json branch)
[[ -n "$branch" ]] || fatal "buildinfo is missing 'branch'"
timestamp=$(echo "$buildinfo" | json timestamp)
[[ -n "$timestamp" ]] || fatal "buildinfo is missing 'timestamp'"
mantaUploadDir=/$tritonAccount/public/builds/triton-origin-image/$branch-$timestamp/
mantaLatestLink=/$tritonAccount/public/builds/triton-origin-image/$branch-latest


# Validate that origin.uuid matches origin.{name,version} as a sanity check.
originManifest=$(triton image get $originUuid)
[[ $(echo "$originManifest" | json name) == "$originName" ]] \
    && [[ $(echo "$originManifest" | json version) == "$originVersion" ]] \
    || fatal "origin.uuid, $originUuid, does not match name@version in image config: $originName@$originVersion"
#XXX Something isn't working here. It was empty in latest build.
originMinPlatform=$(echo "$originManifest" | json 'requirements.min_platform["7.0"]')


trap cleanup ERR

# Hardcoded MANTA_URL b/c can't get from CloudAPI.
export MANTA_URL=https://us-east.manta.joyent.com
export MANTA_USER=$tritonAccount
export MANTA_KEY_ID=$tritonKeyId
unset MANTA_TLS_INSECURE  # not yet supported
unset MANTA_SUBUSER  # not supported


echo "Building $imageName@$imageVersion image"
echo "Manta upload dir:"
echo "    $mantaUploadDir"
echo "Image config:"
echo "$imageConfig" | json | sed -e 's/^/    /'
echo "Triton CLI profile:"
triton profile get | sed -e 's/^/    /'

# Create the proto instance.
echo ""

# Find a package with sufficient RAM, but avoid crazy large packages.
protoPkg=$(triton pkgs -j \
    | json -gac "this.memory >= $protoMinMemoryMb
        && this.memory <= 2 * $protoMinMemoryMb" name \
    | head -1)
protoName="TEMP-$imageName-proto-$(date +%s)"

pkgsrcPkgs="$(echo "$imageConfig" \
    | json -e 'this.flat = this.pkgsrc.join(" ")' flat)"
userScript="/opt/local/bin/pkgin -f -y update"
userScript="${userScript}; /opt/local/bin/pkgin -y in $pkgsrcPkgs"
userScript="${userScript}; touch /.done"

triton instance create -w -n $protoName \
    -m "user-script=$userScript" \
    "$originUuid" "$protoPkg"


# Wait for the user-script to complete.
ip=$(triton instance ip $protoName)
ssh="ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ip"
count=0
set +o errexit
while (( count < 60 )); do
    $ssh "[[ -f /.done ]] || exit 42" >/dev/null && break
    rc=$?
    [[ $rc -ne 42 ]] && fatal "Error during ssh"

    (( count = count + 1 ))
    sleep 15
done
set -o errexit
$ssh "rm /.done"


# Stop the proto and create our image
echo ""
echo "Creating image from proto inst $protoName"
triton instance stop -w $protoName

output=$(triton image create -jw \
    -d "$imageDesc" \
    -t "$(json -f $buildinfoFile -o json-0 branch timestamp git)" \
    --homepage "$imageHomepage" \
    "$protoName" "${imageName}" "${imageVersion}")
echo "$output"
imageUuid=$(echo "$output" | head -1 | json id)
echo "Image UUID: $imageUuid"


# Export the image to our Manta build area
echo ""
mmkdir -p $mantaUploadDir
triton image export $imageUuid $mantaUploadDir
echo $mantaUploadDir | mput $mantaLatestLink   # create the `BRANCH-latest` file
mput -f $buildinfoFile -H 'content-type: application/json' \
    $mantaUploadDir/buildinfo.json
# TODO: want sha256sums or md5sums files in there?

# Tweaks to imgmanifest for publishing.
# - Set requirements.min_platform to that of the origin, because we know we
#   haven't added binary components that depend on the platform on which the
#   proto instance was deployed.
# - Set owner to the "not set" UUID (see IMGAPI-408), as is done by
#   updates.joyent.com itself on import.
imgmanifestName=$(mls $mantaUploadDir | grep '\.imgmanifest')
mget -o build/$imgmanifestName $mantaUploadDir/$imgmanifestName
json -f build/$imgmanifestName -I \
    -e "this.requirements.min_platform['7.0'] = '$originMinPlatform'" \
    -e "this.owner = '00000000-0000-0000-0000-000000000000'"
mput -f build/$imgmanifestName $mantaUploadDir/$imgmanifestName


echo ""
echo "Cleaning up"
triton instance rm -w $protoName
triton image rm -f $imageUuid
