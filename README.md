# triton-origin-image

This repository is part of the Joyent Triton project. See the [contribution
guidelines](https://github.com/joyent/triton/blob/master/CONTRIBUTING.md) --
*Triton does not use GitHub PRs* -- and general documentation at the main
[Triton project](https://github.com/joyent/triton) page.

This repository defines how "triton-origin" images -- for use as the origin
image for core Triton (and Manta) components -- are built. [RFD 46: Origin
images for Triton and Manta core
images](https://github.com/joyent/rfd/tree/master/rfd/0046) is the primary
design document for this repo. The goal is to provide a single (or small set) of
origin images for all Triton and Manta VM components:

- to save space for distribution, and
- to have a well documented common base to help with maintenance.


## tl;dr

- This repo builds one or more "triton-origin-$pkgsrcArch-$originVer@$version"
  images, e.g. "triton-origin-multiarch-15.4.1@1.0.0", and publishes them to
  updates.joyent.com and images.joyent.com. (See the "Building triton-origin
  images" section below.)
- After sanity testing, those images are "released" for use by Triton/Manta
  components. (See the "Releasing triton-origin images" section below.)
- A Triton/Manta core component, say VMAPI, uses one of these images as the
  origin image on which "vmapi" images are built. (See the "How to use
  triton-origin images" section below.)

If you are a Triton/Manta developer working on any of its services, then you
mostly likely only need to care about "How to use triton-origin images".


## How to use triton-origin images

This section has the instructions for a switching a Triton or Manta component
to using a triton-origin image.

1. Find the latest released set of triton-origin images:

        updates-imgadm -C release list --latest name=~triton-origin-

    For example:

        $ updates-imgadm -C release list --latest name=~triton-origin-
        UUID                                  NAME                            VERSION  FLAGS  OS       PUBLISHED
        e24bd5b7-f06b-4d6a-84f1-45c0b342e4d2  triton-origin-multiarch-15.4.1  1.0.0    I      smartos  2017-05-02T06:42:18Z

    and choose the flavour you want. In our example (and at the time of
    writing) there is only *one* flavour, so that's easy.

2. Update `"image_uuid": "<uuid from step 1>"` for your component in
   ["targets.json.in" in
   MG](https://github.com/joyent/mountain-gorilla/blob/master/targets.json.in).
   This tells the MG-based build to use that origin for image creation.

   For example for VMAPI, we'd update
   [here](https://github.com/joyent/mountain-gorilla/blob/53f3f76e4dda86e48dbfd07c61faee9814626b2a/targets.json.in#L603-L604).

3. If you are moving from a *non*-triton-origin image, then you can remove
   the set of pkgsrc packages that are included in triton-origin images
   from the "pkgsrc" field in "targets.json.in". The included triton-origin
   packages are:

        coreutils
        curl
        gsed
        patch
        sudo

4. If your component uses [sdcnode](https://github.com/joyent/sdcnode) (most
   currently do), then you may need to update `NODE_PREBUILT_` variables in
   your Makefile. You probably have a block like this:

        NODE_PREBUILT_VERSION=v4.6.1
        ifeq ($(shell uname -s),SunOS)
            NODE_PREBUILT_TAG=zone
            # This is sdc-minimal-multiarch-lts@15.4.1, compat with
            # triton-origin-multiarch-15.4.1.
            NODE_PREBUILT_IMAGE=18b094b0-eb01-11e5-80c1-175dac7ddf02
        endif

    That `NODE_PREBUILT_IMAGE` value needs to be the image UUID of sdcnode
    builds which are *compatible* with the triton-origin flavour you are using.
    "Compatible" here means that it is based on the same `$pkgsrcArch` and
    `$baseVersion` of the minimal/base origin image. Use the "sdcnode
    compatibility with triton-origin images" table and example below.

    For example, say you are using "triton-origin-multiarch-15.4.1@1.0.1".
    That is [based on](./images.json#L5-L9) "minimal-multiarch-lts@15.4.1".
    From <https://download.joyent.com/pub/build/sdcnode/README.html> we see
    that there are sdcnode builds for "sdc-minimal-multiarch-lts@15.4.1:
    18b094b0-eb01-11e5-80c1-175dac7ddf02". Therefore we want:

        NODE_PREBUILT_IMAGE=18b094b0-eb01-11e5-80c1-175dac7ddf02

5. Update Jenkins (Joyent's current CI system) configuration for your
   component's job to get an appropriate Jenkins Agent. Specifically the
   "Label Expression" of the job configuration needs to be updated.
   See the compatibility table below.


### sdcnode compatibility with triton-origin images

Ultimately the authority for which sdcnode builds and triton-origin images are
available is in the [triton-origin images.json](./images.json) and [sdcnode
nodeconfigs.json](https://github.com/joyent/sdcnode/blob/master/nodeconfigs.json)
files. We will try to keep this table up to date:

| triton-origin image            | based on                     | sdcnode compatible build         | `NODE_PREBUILT_VERSION`              |
| ------------------------------ | ---------------------------- | -------------------------------- | ------------------------------------ |
| triton-origin-multiarch-15.4.1 | minimal-multiarch-lts@15.4.1 | sdc-minimal-multiarch-lts@15.4.1 | 18b094b0-eb01-11e5-80c1-175dac7ddf02 |
| -                              | -                            | sdc-base@14.2.0                  | de411e86-548d-11e4-a4b7-3bb60478632a |
| -                              | -                            | sdc-multiarch@13.3.1             | b4bdc598-8939-11e3-bea4-8341f6861379 |
| -                              | -                            | sdc-smartos@1.6.3                | fd2cc906-8938-11e3-beab-4359c665ac99 |


- Q: Why does sdcnode have "sdc-"-prefixed images?
  A: Because that's what we did before RFD 46 and triton-origin images. We
  copied the public "base/smartos/minimal" image and prefixed with "sdc-" to
  allow having a different lifetime for Triton component origin images than
  for public usage of those images. This was partially necessitated because
  many Triton/Manta components still use the long deprecated "smartos@1.6.3"
  origin image. Eventually, these sdcnode flavours will be phased out.


### Joyent Jenkins agent labels compatibility with triton-origin images

| triton-origin image            | Jenkins agent labels                      |
| ------------------------------ | ----------------------------------------- |
| triton-origin-multiarch-15.4.1 | image_ver:15.4.1 && pkgsrc_arch:multiarch |

See the internal <https://mo.joyent.com/docs/engdoc/master/jenkins/index.html#agent-labels>
for details.


## Development of triton-origin images

The triton-origin images to be built are defined in
[images.json](./images.json). This set should remain small to avoid having a
large number of origin images in play that can increase the size of the Triton
headnode build on the USB key; and to avoid a large testing/maintenance surface
area.

The active set of triton-origin images is defined by which of them is being
used by any current Triton/Manta component images. Currently that is the
set of `image_uuid` UUID values in [MG's
targets.json.in](https://github.com/joyent/mountain-gorilla/blob/master/targets.json.in),
e.g.: <https://github.com/joyent/mountain-gorilla/blob/37a58ef3c5/targets.json.in#L162-L163>.
Those UUIDs refer to origin images published to <https://updates.joyent.com>.


### Naming and versioning

Triton-origin images are named and versioned as follows:

    name = "triton-origin-$pkgsrcArch-$originVer"
    version = "<version string from ./package.json>"

where `$pkgsrcArch` is one of "multiarch" (the typical arch, per discussion in
RFD 46), "i386", or "x86\_64"; and "$originVer" is the version of the origin
image on which the triton-origin image is based.

For example, a triton-origin image based on "minimal-multiarch-lts@15.4.1" will
be "triton-origin-multiarch-15.4.1@1.2.3" (assuming "1.2.3" is the package.json
version). See the "Naming and versioning" section in RFD 46 for some
justification.


### Building triton-origin images

For Joyent Engineering, the "triton-origin-image" Jenkins job handles building
triton-origin images for pushes to "master". However, you can build them
directly as follows.

*First*, to build all the images and export them to Manta
(at "/$tritonAccount/public/builds/triton-origin-image/$branch-$timestamp/"):

    make clean all

This will use **your current `triton` CLI profile and `MANTA_*` settings**.
There is an assumption that this Triton DataCenter has an associated Manta
(which is a requirement for
[ExportImage](https://apidocs.joyent.com/cloudapi/#ExportImage)) *and*,
currently, that **this is the production Manta in us-east
<https://us-east.manta.joyent.com>**. The latter is because of a limitation in
CloudAPI that doesn't provide a programmatic way to get the Manta URL with which
the DC's IMGAPI is associated, if any.

(Note: The upload path in Manta roughly follows the pattern used for building
Triton and Manta components. See <https://github.com/joyent/mountain-gorilla>
and, for Joyent Engineering builds see
`/Joyent_Dev/public/builds/triton-origin-image` in Joyent's us-east Manta.)


*Second*, publish the built images to <https://updates.joyent.com>:

    make publish

This will use **your current `UPDATES_IMGADM_*` settings**, which requires you
to have publish credentials to updates.jo. If this is the "master" branch, then
the images will be published to the "dev" channel of updates.jo. Otherwise, they
will be published to the "experimental" channel of updates.jo.


### Testing a new triton-origin image

[Currently](https://github.com/joyent/mountain-gorilla/blob/53f3f76e4dda86e48dbfd07c61faee9814626b2a/tools/prep_dataset_in_jpc.sh#L45),
core component image creation is done in us-east-3. This means that to build
a core component with a new unreleased triton-origin image requires manually
importing that image to us-east-3 and making it available to, at least,
the `Joyent_Dev` account that is currently used for CI builds.

For example:

    ssh us-east-3

    theImage=$(updates-imgadm -C dev list \
        name=triton-origin-multiarch-15.4.1 --latest -H -o uuid)
    joyentDev=$(sdc-useradm get Joyent_Dev | json uuid)

    sdc-imgadm import $theImage -S https://updates.joyent.com
    sdc-imgadm add-acl $theImage $joyentDev

Once you have done this, you should be able to get a build -- of, say,
"amonredis" -- as follows (instructions are for Joyent developers with access
to our CI system):

1. Create a feature branch (e.g. "FOO-123") of [MG](https://github.com/joyent/mountain-gorilla)
   changing amonredis's `image_uuid` to your new image:

        --- a/targets.json.in
        +++ b/targets.json.in
        @@ -298,8 +298,8 @@ cat <<EOF
             "image_name": "amonredis",
             "image_description": "SDC Amon Redis",
             "image_version": "1.0.0",
        -    "// image_uuid": "triton-origin-multiarch-15.4.1@1.0.1",
        -    "image_uuid": "04a48d7d-6bb5-4e83-8c3b-e60a99e0f48f",
        +    "// image_uuid": "triton-origin-multiarch-18.1.0@1.1.0",
        +    "image_uuid": "$theImage",
             "pkgsrc": [],
             "repos": [
               {"url": "git@github.com:joyent/sdc-amonredis.git"}

2. Push that feature branch to GitHub.

3. Do a [build of "amonredis"](https://jenkins.joyent.us/job/amonredis/)
   setting `TRY_BRANCH` to your feature branch name, e.g. `TRY_BRANCH=FOO-123`.

When that build completes, there will be a new image build in the "experimental"
channel of updates.joyent.com, e.g.:

    updates-imgadm -C experimental list name=amonredis

If you forget to step to make the triton-origin image accessible to `Joyent_Dev`
in us-east-3, then you will see a build error something like this:

    ./tools/prep_dataset_in_jpc.sh:226: sdc-createmachine --dataset 04a48d7d-6bb5-4e83-8c3b-e60a99e0f48f --package 14b0351e-d0f8-11e5-8a78-9fb74f9e7bc3 --tag MG_IMAGE_BUILD=true --name TEMP-vmapi-1494370819
    sdc-createmachine: error (ResourceNotFound): image 04a48d7d-6bb5-4e83-8c3b-e60a99e0f48f not found
    ...
    prep_dataset_in_jpc.sh: error: cannot get uuid for new VM.


### Releasing triton-origin images

Fully releasing triton-origin images for Triton and Manta releases (i.e., for
images that make it to the updates.joyent.com "release" channel) and for public
usage (e.g. per Triton developer guide documentation) is a manual process.
Benefits of this being manual:

- We hopefully **reduce the number of active triton-origin images in use**. In
  the extreme, if every Triton component used a different triton-origin image,
  we could lose the space benefits on the USB key and on zpools for deployment.
- We use this opportunity to **also publish the new triton-origin images to
  images.joyent.com and to the Triton Public Cloud**. These triton-origin images
  are necessary for non-Joyent users (who don't have direct access to our
  CI system) to [build Triton components
  themselves](https://github.com/joyent/triton/blob/master/docs/developer-guide/building.md).

A downside is that we have to bother with a manual release process. However,
I don't expect there to be much churn on triton-origin images, so I doubt it
will be much of a burden.

How to release a new set of triton-origin images:

1. List the set images in the "dev" channel to release via:

        updates-imgadm -C dev list --latest \
            name=~triton-origin- version=$(json -f package.json version)

    For example:

        $ updates-imgadm -C dev list --latest name=~triton-origin- version=1.0.0
        UUID                                  NAME                            VERSION  FLAGS  OS       PUBLISHED
        e24bd5b7-f06b-4d6a-84f1-45c0b342e4d2  triton-origin-multiarch-15.4.1  1.0.0    I      smartos  2017-05-02T06:42:18Z

2. Create a [TRITON](https://devhub.joyent.com/jira/browse/TRITON) ticket to
   note the release of new triton-origin images. Include the listing from
   step 1.

3. Add those images to all of the "release" (required for Triton releases),
   "staging" (required for the Triton release process), "experimental" (needed
   for feature-branch builds of components), and "support" (required eventually
   when Support takes release images) channels of updates.joyent.com:

        imageUuids=$(updates-imgadm -C dev list -H -o uuid --latest \
            name=~triton-origin- version=$(json -f package.json version) | xargs)
        updates-imgadm -C dev channel-add staging $imageUuids
        updates-imgadm -C dev channel-add release $imageUuids
        updates-imgadm -C dev channel-add experimental $imageUuids
        updates-imgadm -C dev channel-add support $imageUuids

    (Dev Note: One might hit TOOLS-1733 while doing this.)

4. Publish the images to <https://images.joyent.com>: This is a first step in
   getting them available for non-Joyent users to build Triton components
   themselves.

   TODO: provide a tool to do this. For now you need to download each from
   updates.jo, tweak `public: true` in the manifest, and then use
   `joyent-imgadm` to publish them to images.jo.

5. Open a CM ticket to have the new triton-origin images get imported into
   the TPC datacenters.

6. If this is a new triton origin name (e.g. adding a triton-origin image
   based on a new minimal image -- new pkgsrc arch or new pkgsrc version), then
   a few extra things are required:

   - Add entries to the "compatibility" tables in the "sdcnode compatibility
     with triton-origin images" and "Joyent Jenkins agent labels compatibility
     with triton-origin images" sections above.
   - Build and provision new Jenkins Agents to Joyent Engineering's CI system
     for building core components on this image. See
     <https://github.com/joyent/jenkins-agent> for details and speak to JoshW,
     ChrisB, or Trent.
   - Add sdcnode builds for this new image. See
     <https://github.com/joyent/sdcnode> and speak to Trent.


### Warning: minimal 16.4.1

The 16.4.x generation of base/minimal images has issue DATASET-1297
("base-64-lts 16.4.1 image is broken: does not work on platforms older than
20161108T160947Z"), which is a blocker for triton-origin usage. JoshW mentions
that to use these we could run them through the deholer.

### Limitation: hardcoded "mantaUrl"

Currently there is no good way to infer the linked `MANTA_URL` for a given
Triton CLI profile (aka CloudAPI). It would be nice to have that on the
cloudapi's ListServices. Therefore we currently hardcode the Manta URL in the
scripts.


## License

MPL 2.0
