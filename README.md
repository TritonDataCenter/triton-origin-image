# triton-origin-image

This repository is part of the Joyent Triton project. See the [contribution
guidelines](https://github.com/joyent/triton/blob/master/CONTRIBUTING.md) --
*Triton does not use GitHub PRs* -- and general documentation at the main
[Triton project](https://github.com/joyent/triton) page.

This repository defines how "triton-origin" images -- for as the origin image for
core Triton (and Manta) components -- are built. See [RFD 0046: RFD 46 Origin
images for Triton and Manta core
images](https://github.com/joyent/rfd/tree/master/rfd/0046) is the primary
design document for this repo. The goal is to provide a single (or small set) of
origin images for all Triton and Manta VM components:

- to save space for distribution, and
- to have a well documented common base to help with maintenance.



## tl;dr

- This repo builds one or more "triton-origin-$pkgsrcArch-$originVer@$version"
  images, e.g. "triton-origin-multiarch-15.4.1@1.0.0", and publishes them to
  updates.joyent.com. (See the "Building triton-origin images" section below.)
- After sanity testing, those images are "released" for use by Triton/Manta
  components. (See the "Releasing triton-origin images" section below.)
- A Triton/Manta core component, say VMAPI, uses one of these images as the
  origin image on which "vmapi" images are built. (See the "How to use
  triton-origin images" section below.)


## How to use triton-origin images

TODO: Notes for how Triton/Manta components should choose a triton-origin
flavour, and find a current UUID; and any other implications, like the
`NODE_PREBUILD_IMAGE` value in their Makefile.


## Development of triton-origin images

The triton-origin images to be built are defined in
[images.json](./images.json). This set should remain small to avoid having a
large number of origin images in play that can increase the size of the Triton
headnode build on the USB key; and to avoid testing/maintenance surface area.

At this time, the active set of triton-origin images is defined by the
Triton/Manta components' `image_uuid` UUID value in [MG's
targets.json.in](https://github.com/joyent/mountain-gorilla/blob/master/targets.json.in).
Those UUIDs refer to origin images published to <https://updates.joyent.com>.


### Naming and versioning

Triton-origin images are named and versioned as follows:

    name = "triton-origin-$pkgsrcArch-$originVer"
    version = <version string from ./package.json>

where `$pkgsrcArch` is one of "multiarch" (the typical arch per discussion in
RFD 46), "i386", or "x86\_64"; and "$originVer" is the version of the origin
image on which the triton-origin image is based.

For example, a triton-origin image based on "minimal-multiarch-lts@15.4.1" will
be "triton-origin-multiarch-15.4.1@1.2.3" (assuming "1.2.3" is the package.json
version). See the "Naming and versioning" section in RFD for some justification.


### Building triton-origin images

*First*, To build all the images and export them to Manta
(at "/$tritonAccount/public/builds/triton-origin-image/$branch-$timestamp/"):

    make clean all

This will use **your current `triton` CLI profile and `MANTA_*` settings**.
There is an assumption that this Triton DataCenter has an associated Manta
(which is a requirement for
[ExportImage](https://apidocs.joyent.com/cloudapi/#ExportImage)) *and*,
currently, that **this is the production Manta in us-east
<https://us-east.manta.joyent.com>**. The latter is because of a limitation in
CloudAPI that doesn't provide a programmatic way to get the Manta URL with which
the DC is associated, if any.

The upload path in Manta roughly follows the pattern used for building Triton
and Manta components. See <https://github.com/joyent/mountain-gorilla>.


*Then*, publish the built images to <https://updates.joyent.com>:

    make publish

This will use **your current `UPDATES_IMGADM_*` settings**, which requires you
to have publish credentials to updates.jo. If this is the "master" branch, then
the images will be published to the "dev" channel of updates.jo. Otherwise,
they will be published to the "experimental" channel of updates.jo.


### Releasing triton-origin images

The steps above will build and publish new triton-origin images to the "dev"
channel of updates.jo. A Triton component, say VMAPI, *could* use that new
triton-origin image in the "dev" channel. However, we would rather have a
controlled process where there is an explicit manual step to release new
triton-origin images. Benefits:

- We hopefully **reduce the number of active triton-origin images in use**. In
  the extreme, if every Triton component used a different triton-origin image,
  we could lose the space benefits on the USB key and on zpools for deployment.
- We use this explicit process to **publish new triton-origin images to
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
   "staging" (required for the Triton release process), and "support"
   (required eventually when Support takes release images) channels of
   updates.joyent.com:

        imageUuids=$(updates-imgadm -C dev list -H -o uuid --latest \
            name=~triton-origin- version=$(json -f package.json version) | xargs)
        updates-imgadm -C dev channel-add staging $imageUuids
        updates-imgadm -C dev channel-add release $imageUuids
        updates-imgadm -C dev channel-add support $imageUuids

4. Publish the images to <https://images.joyent.com>: This is a first step in
   getting them available for non-Joyent users to build Triton components
   themselves.

   TODO: provide a tool to do this. For now you need to download each from
   updates.jo and then use `joyent-imgadm` to publish them to images.jo.

5. Open a CM ticket to have the new triton-origin images get imported into
   the TPC datacenters.


### Warning: minimal 16.4.1

The 16.4.x generation of base/minimal images has issue DATASET-1297
("base-64-lts 16.4.1 image is broken: does not work on platforms older than
20161108T160947Z"), which is a blocker for triton-origin usage. JoshW mentions
that to use these we could run them through the deholer.

### Limitation: hardcode "mantaUrl"

Currently there is no good way to infer the linked `MANTA_URL` for a given
Triton CLI profile (aka CloudAPI). It would be nice to have that on the
cloudapi's ListServices. Therefore we currently hardcode the Manta URL in the
scripts.


## License

MPL 2.0
