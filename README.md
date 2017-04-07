# triton-origin-image

This repository is part of the Joyent Triton project. See the [contribution
guidelines](https://github.com/joyent/triton/blob/master/CONTRIBUTING.md) --
*Triton does not use GitHub PRs* -- and general documentation at the main
[Triton project](https://github.com/joyent/triton) page.

This repository defines how to build an image for use as an origin image for
core Triton (and Manta) components, per [RFD
46](https://github.com/joyent/rfd/blob/master/rfd/0046/README.md).

tl;dr:

- This repo builds a "triton-origin-multiarch@1.0.0", say,
  image and publishes it to updates.joyent.com.
- A Triton core component, say VMAPI, uses this image as the origin
  image on which "vmapi" images are built. 


## How to build and publish a new triton-origin image

TODO

Something along the lines of:

- `make SOMETHING` to build an image using the current code
- `make SOMETHING` to publish it to updates.jo
- Setup a new Jenkins build zone using this image for sdcnode builds
- Update sdcnode.git to get sdcnode builds for this new image.


## License

MPL 2.0
