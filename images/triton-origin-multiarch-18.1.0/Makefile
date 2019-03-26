# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2019 Joyent, Inc.
#

NAME=triton-origin-multiarch-18.1.0
TOP=$(shell git rev-parse --show-toplevel)

include $(TOP)/Makefile.origin.defs
include $(TOP)/deps/eng/tools/mk/Makefile.defs

# minimal-multiarch@18.1.0
BASE_IMAGE_UUID = 1ad363ec-3b83-11e8-8521-2f68a4a34d5d
BUILDIMAGE_NAME = ${NAME}
BUILDIMAGE_DESC = Triton/Manta component origin image based on multiarch 18.1.0
BUILDIMAGE_PKGSRC = coreutils-8.26 curl-7.59.0 gsed-4.4 patch-2.7.6 sudo-1.8.22

include $(TOP)/deps/eng/tools/mk/Makefile.targ
