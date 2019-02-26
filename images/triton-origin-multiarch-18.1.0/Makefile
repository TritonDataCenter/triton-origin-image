NAME=triton-origin-multiarch-18.1.0

include ../../deps/eng/tools/mk/Makefile.defs
TOP=$(shell git rev-parse --show-toplevel)
MAKE_STAMPS_DIR=$(TOP)/make_stamps

# not actually "building" anything for the image
export ENGBLD_SKIP_VALIDATE_BUILDENV=true

# minimal-multiarch-lts@18.1.0
BASE_IMAGE_UUID = 1ad363ec-3b83-11e8-8521-2f68a4a34d5d
BUILDIMAGE_NAME = ${NAME}
BUILDIMAGE_DESC = Triton/Manta component origin image based on multiarch 18.1.0
#AGENTS          = 
BUILDIMAGE_PKGSRC = coreutils-8.26 curl-7.59.0 gsed-4.4 patch-2.7.6 sudo-1.8.22

#
# The default image contents are set to $(TOP)/$(RELEASE_TARBALL)
# in Makefile.targ. To override those, set $(BUILDIMAGE_PKG) to the
# full path of the required tarball.
#
BUILDIMAGE_PKG=$(TOP)/empty.tar.gz
#

include ../..//deps/eng/tools/mk/Makefile.targ

