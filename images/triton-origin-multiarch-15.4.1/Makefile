NAME=triton-origin-multiarch-15.4.1

ENGBLD_USE_BUILDIMAGE=true



include ../../deps/eng/tools/mk/Makefile.defs
TOP=$(shell git rev-parse --show-toplevel)

# not actually "building" anything for the image
export ENGBLD_SKIP_VALIDATE_BUILDENV=true

# minimal-multiarch-lts@15.4.1
BASE_IMAGE_UUID = ede31770-e19c-11e5-bb6e-3b7de3cca9ce
BUILDIMAGE_NAME = ${NAME}
BUILDIMAGE_DESC = Triton/Manta component origin image based on multiarch 15.4.x
#AGENTS          = 
BUILDIMAGE_PKGSRC = coreutils-8.23nb2 curl-7.51.0 gsed-4.2.2nb4 patch-2.7.5 sudo-1.8.15
#
# The default image contents are set to $(TOP)/$(RELEASE_TARBALL)
# in Makefile.targ. To override those, set $(BUILDIMAGE_PKG) to the
# full path of the required tarball.
#
BUILDIMAGE_PKG=$(TOP)/empty.tar.gz
#


include ../..//deps/eng/tools/mk/Makefile.targ

