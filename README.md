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
  images and publishes them to updates.joyent.com.
- After sanity testing, those images are "released" for use by Triton/Manta
  components. (See the "Releasing triton-origin images" section below.)
- A Triton/Manta core component, say VMAPI, uses one of these images as the
  origin image on which "vmapi" images are built.


## Details

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


## Building triton-origin images

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


## Releasing triton-origin images

The steps above will build and publish new triton-origin images to the "dev"
channel of updates.jo. However, for a *release* version of Triton components
to use these images, they need to **make it to the "release" channel of
updates.jo**. We'll call that "releasing" the triton-origin images.

TODO(trentm): I need to verify if manually releasing the triton-origin images
(adding them to the "release" channel) is necessary, or if it happens (or
should happen) automatically as part of building component images to the
"staging" channel as part of the Triton release process.


## Notes for consumers

TODO: Notes for how Triton/Manta components should choose a triton-origin
flavour, and find a current UUID; and any other implications, like the
`NODE_PREBUILD_IMAGE` value in their Makefile.


## Dev Notes

### minimal 16.4.1

This generation has issue DATASET-1297 (base-64-lts 16.4.1 image is broken: does
not work on platforms older than 20161108T160947Z), which is a blocker for
triton-origin usage. JoshW mentions that to use these we could run them
through the deholer.


### hardcode "mantaUrl"

Currently there is no good way to infer the linked `MANTA_URL` for a given
Triton CLI profile (aka CloudAPI). It would be nice to have that on the
cloudapi's ListServices. Therefore we need to hardcode the Manta URL in the
scripts.


## License

MPL 2.0
