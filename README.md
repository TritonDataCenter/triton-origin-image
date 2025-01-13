# triton-origin-image

This repository is part of the Triton Data Center project. See the
[contribution
guidelines](https://github.com/TritonDataCenter/triton/blob/master/CONTRIBUTING.md)
and general documentation at the main [Triton
project](https://github.com/TritonDataCenter/triton) page.

This repository defines how "triton-origin" images -- for use as the origin
image for core Triton (and Manta) components -- are built. [RFD 46: Origin
images for Triton and Manta core
images](https://github.com/TritonDataCenter/rfd/tree/master/rfd/0046) is the
primary design document for this repo. The goal is to provide a single (or
small set) of origin images for all Triton and Manta VM components:

- to save space for distribution, and
- to have a well documented common base to help with maintenance.


## tl;dr

- This repo builds one or more "triton-origin-$pkgsrcArch-$originVer@$version"
  images, e.g. "triton-origin-x86_64-19.4.0@master-20200130T200825Z-gbb45b8d",
  and publishes them to updates.tritondatacenter.com. (See the "Building
  triton-origin images" section below.)
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
        UUID                                  NAME                            VERSION                           FLAGS  OS       PUBLISHED
        04a48d7d-6bb5-4e83-8c3b-e60a99e0f48f  triton-origin-multiarch-15.4.1  1.0.1                             I      smartos  2017-05-09T22:06:48Z
        59ba2e5e-976f-4e09-8aac-a4a7ef0395f5  triton-origin-x86_64-19.4.0     master-20200130T200825Z-gbb45b8d  I      smartos  2020-01-30T20:11:05Z

    and choose the flavour you want.  The "19.4.0" refers to the
    "minimal-$arch-$version" origin image of the "triton-origin-\*" image.
    Generally you should favour later versions -- "19.4.0" in this example.

2. Update `BASE_IMAGE_UUID` in your component's `Makefile`.

3. If you are moving from a *non*-triton-origin image, then you can remove
   the set of pkgsrc packages that are included in triton-origin images
   Likely packages include:

        coreutils
        curl
        gsed
        patch
        sudo

4. If your component uses [sdcnode](https://github.com/TritonDataCenter/sdcnode) (most
   currently do), then you may need to update `NODE_PREBUILT_` variables in
   your Makefile. You probably have a block like this:

        NODE_PREBUILT_VERSION=v8.17.0
        ifeq ($(shell uname -s),SunOS)
            NODE_PREBUILT_TAG=zone64
            # This is minimal-64 19.4.0, compat with
            # triton-origin-x86_64-19.4.0
            NODE_PREBUILT_IMAGE=5417ab20-3156-11ea-8b19-2b66f5e7a439
        endif

    That `NODE_PREBUILT_IMAGE` value needs to be the image UUID of sdcnode
    builds which are *compatible* with the triton-origin flavour you are using.
    "Compatible" here means that it is based on the same `$pkgsrcArch` and
    `$baseVersion` of the minimal/base origin image. Use the "sdcnode
    compatibility with triton-origin images" table and example below.

    For example, say you are using "triton-origin-x86_64-19.4.0@master-20200130T200825Z-gbb45b8d".
    That is based on "minimal-64-lts@19.4.0".
    From <https://us-central.manta.mnx.io/Joyent_Dev/public/releng/sdcnode/README.html> we see
    that there are sdcnode builds for "minimal-64-lts@19.4.0":
    5417ab20-3156-11ea-8b19-2b66f5e7a439". Therefore we want:

        NODE_PREBUILT_IMAGE=5417ab20-3156-11ea-8b19-2b66f5e7a439

5. Update Jenkinsfile to add a stage for the image you're building, taking care
   to specify the correct `joyCommonLabels(..)` expression for your image,
   adding a parameter to allow building of the individual image, and modifying
   the `make` command line arguments for your pipeline stage.
   See the compatibility table below.


### sdcnode compatibility with triton-origin images

Ultimately the authority for which sdcnode builds and triton-origin images are
available is defined in this repo and [sdcnode
nodeconfigs.json](https://github.com/TritonDataCenter/sdcnode/blob/master/nodeconfigs.json)
files. We will try to keep this table up to date:

| triton-origin image            | based on                     | sdcnode compatible build         | `NODE_PREBUILT_VERSION`              |
| ------------------------------ | ---------------------------- | -------------------------------- | ------------------------------------ |
| triton-origin-x86\_64-21.4.0   | minimal-64-lts@21.4.0        | minimal-64-lts@21.4.0            | a7199134-7e94-11ec-be67-db6f482136c2 |
| triton-origin-x86\_64-19.4.0   | minimal-64-lts@19.4.0        | minimal-64-lts@19.4.0            | 5417ab20-3156-11ea-8b19-2b66f5e7a439 |
| triton-origin-x86\_64-18.4.0   | minimal-64-lts@18.4.0        | minimal-64-lts@18.4.0            | c2c31b00-1d60-11e9-9a77-ff9f06554b0f |
| triton-origin-multiarch-15.4.1 | minimal-multiarch-lts@15.4.1 | sdc-minimal-multiarch-lts@15.4.1 | 18b094b0-eb01-11e5-80c1-175dac7ddf02 |
| -                              | -                            | sdc-smartos@1.6.3                | fd2cc906-8938-11e3-beab-4359c665ac99 |


- Q: Why are the image names for some "sdcnode compatible build"s prefixed
  with "sdc-"?
  A: Because that's what we did before RFD 46 and triton-origin images. We
  copied the public "base/smartos/minimal" image and prefixed with "sdc-" to
  allow having a different lifetime for Triton component origin images than
  for public usage of those images. This was partially necessitated because
  many Triton/Manta components still use the long deprecated "smartos@1.6.3"
  origin image. Eventually, these sdcnode flavours will be phased out.


### Jenkins agent labels compatibility with triton-origin images

| triton-origin image            | Jenkins agent labels                        |
| ------------------------------ | ------------------------------------------- |
| triton-origin-x86\_64-24.4.1   | `image_ver:24.4.1 && pkgsrc_arch:x86_64`    |
| triton-origin-x86\_64-23.4.0   | `image_ver:23.4.0 && pkgsrc_arch:x86_64`    |
| triton-origin-x86\_64-21.4.0   | `image_ver:21.4.0 && pkgsrc_arch:x86_64`    |
| triton-origin-x86\_64-19.4.0   | `image_ver:19.4.0 && pkgsrc_arch:x86_64`    |
| triton-origin-x86\_64-18.4.0   | `image_ver:18.4.0 && pkgsrc_arch:x86_64`    |
| triton-origin-multiarch-15.4.1 | `image_ver:15.4.1 && pkgsrc_arch:multiarch` |

See the internal
<https://engdoc.tritondatacenter.com/jenkins/index.html#agent-labels> for
details.


## Development of triton-origin images

The triton-origin images to be built are defined in Makefiles that reside in
the `images` directory.  They use
[engbld](https://github.com/TritonDataCenter/eng/) just like the components
themselves do. This set should remain small to avoid having a large number of
origin images in play that can increase the size of the Triton headnode build
on the USB key; and to avoid a large testing/maintenance surface area.

The active set of triton-origin images is defined by which of them is being used
by any current Triton/Manta component images. That is the `BASE_IMAGE_UUID` of
all active components.

Those UUIDs refer to origin images published to
<https://updates.tritondatacenter.com>.


### Prerequisite Chains

An intended invariant of an image repository (such as
updates.tritondatacenter.com) is that the full origin chain of images for any
image in that repository are also contained within the same repository (and in
the same channel).  That means the image that a triton-origin image is "based
on" (the origin of the origin) must be imported into
updates.tritondatacenter.com from images.tritondatacenter.com.  This would
typically be a minimal base image.

NOTE: As of the triton-origin-image 23.4.0 release, new minimal-64-lts images
are published to updates.tritondatacenter.com as part of the pkgsrc release
process, so the instructions below are no longer required.

NOTE: Because updates.tritondatacenter.com is a "standalone" imgapi instance,
it does not support the `-S` flag to `import`.

0. Use an updates.tritondatacenter.com operator account.
1. Locally download the manifest and file of the desired image from
   images.tritondatacenter.com (`images-imgadm get` and
   `images-imgadm get-file`).
2. Edit the manifest to set `public: false` (updates.tritondatacenter.com is a
   "private Images API" and disallows public images).
3. Import the image ex: `./bin/updates-imgadm import -m foo.m -f foo.file`
4. Use `updates-imgadm channel-add` to add the image to the `dev` and
   `experimental` channel if it is not already.
5. Before the image can be used in any released images, it must also be added to
   the remaining channels (`updates-imgadm channels`).


### Naming and versioning

Triton-origin images are named and versioned as follows:

    name = "triton-origin-$pkgsrcArch-$originVer"
    version = "branch-timestamp-commit"

where `$pkgsrcArch` is one of "multiarch" (the typical arch, per discussion in
RFD 46), "i386", or "x86\_64"; and "$originVer" is the version of the origin
image on which the triton-origin image is based.  The version stamp is the same
style currently used by Triton/Manta components.

NOTE: Older origin-images used an `x.y.z` style version string.

See the "Naming and versioning" section in RFD 46 for some justification, and
RFD 165 for later revisions.


### Building triton-origin images

Official builds are done by the "triton-origin-image.git" Jenkins job. This job
does not build automatically, and will only build the pipeline stages you
select as parameters at build-time.

You can build images on your workstation using the standard engbld targets (such
as `buildimage` or `bits-upload`).  Because there are multiple origin images
defined, there are a few different ways to invoke the targets.  Examples:

 * `make triton-origin-x86_64-19.4.0-buildimage` (Convenience wrapper.)
 * `cd images/triton-origin-x86_64-19.4.0 && make buildimage`
 * `make all-buildimage` (To build all images)

NOTE: due to the inherent chicken-and-egg problem, when creating a new
triton-origin image it will need to be built on a previous image, as there will
(obviously) be no Jenkins agents running the yet-to-be-created image.  As an
example, the 23.4.0 triton-origin-image was built on a 21.4.0 agent.

### Testing a new triton-origin image

You can use whatever process you would normally use to test regular components,
this will most likely look something like:

 * Push your changes to a branch
 * Have the appropriate Jenkins origin-image job build it
 * Note the resulting UUID, update one or more components to use that as their base.
 * Test those components as with any other change.


### Releasing triton-origin images

Fully releasing triton-origin images for Triton and Manta releases (i.e., for
images that make it to the updates.tritondatacenter.com "release" channel) and
for public usage (e.g. per Triton developer guide documentation) is a manual
process.  Benefits of this being manual:

- We hopefully **reduce the number of active triton-origin images in use**. In
  the extreme, if every Triton component used a different triton-origin image,
  we could lose the space benefits on the USB key and on zpools for deployment.

A downside is that we have to bother with a manual release process. However, I
don't expect there to be much churn on triton-origin images, so I doubt it will
be much of a burden.  The most common reason to release a new origin-image of an
already existing flavor is the pick up pkgsrc security updates.

If downstream components wish to pick up all security updates at build time
(without waiting for an origin update) they can set:

```
BUILDIMAGE_DO_PKGSRC_UPGRADE:=true
```

How to release a new triton-origin image:

1. List the set images in the "dev" channel to release via:

        updates-imgadm -C dev list --latest \
            name=~triton-origin-

    For example:

        $ updates-imgadm -C release list --latest name=~triton-origin-
        UUID                                  NAME                            VERSION                           FLAGS  OS       PUBLISHED
        04a48d7d-6bb5-4e83-8c3b-e60a99e0f48f  triton-origin-multiarch-15.4.1  1.0.1                             I      smartos  2017-05-09T22:06:48Z
        59ba2e5e-976f-4e09-8aac-a4a7ef0395f5  triton-origin-x86_64-19.4.0     master-20200130T200825Z-gbb45b8d  I      smartos  2020-01-30T20:11:05Z

2. Create a [TRITON](https://mnx.atlassian.net/browse/TRITON) ticket to
   note the release of new triton-origin images. Include the listing from
   step 1.

3. Add the image to all of the "release" (required for Triton releases),
   "staging" (required for the Triton release process), "experimental" (needed
   for feature-branch builds of components), and "support" (required eventually
   when Support takes release images) channels of updates.tritondatacenter.com:

        updates-imgadm -C dev channel-add staging $UUID
        updates-imgadm -C dev channel-add release $UUID
        updates-imgadm -C dev channel-add experimental $UUID
        updates-imgadm -C dev channel-add support $UUID

    (Dev Note: One might hit TOOLS-1733 while doing this.)

4. If this is a new triton origin name (e.g. adding a triton-origin image
   based on a new minimal image -- new pkgsrc arch or new pkgsrc version), then
   a few extra things are required:

   - Add entries to the "compatibility" tables in the "sdcnode compatibility
     with triton-origin images" and "Jenkins agent labels compatibility
     with triton-origin images" sections above.
   - Build and provision new Jenkins Agents to Triton Engineering's CI system
     for building core components on this image. See
     <https://github.com/TritonDataCenter/jenkins-agent> for details.
   - Add sdcnode builds for this new image. See
     <https://github.com/TritonDataCenter/sdcnode>.

5. [eng.git](https://github.com/TritonDataCenter/eng/) includes a script
   `./tools/validate-buildenv.sh` which must be updated to include mappings for
    the new origin image. After pushing changes to eng.git, any components which
    are expected to use the new origin image will need their `deps/eng`
    submodule to be updated.

    These mappings are:
      * `$PKGSRC_MAP`: the human-readable pkgsrc version (e.g. 2019Q4)
      * `$SDC_MAP`: the human-readable name of the origin image
        (e.g. triton-origin-x86_64-19.4.0@master-20200130T200825Z-gbb45b8d)
      * `$JENKINS_AGENT_MAP`: the corresponding jenkins-agent image uuid
      * `$PKGSRC_PKGS_*``: the list of pkgsrc packages expected to be present on
        the build machine


## License

MPL 2.0
