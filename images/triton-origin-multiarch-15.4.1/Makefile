# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2019 Joyent, Inc.
#

NAME=triton-origin-multiarch-15.4.1
TOP=$(shell git rev-parse --show-toplevel)

include $(TOP)/Makefile.origin.defs
include $(TOP)/deps/eng/tools/mk/Makefile.defs

# minimal-multiarch-lts@15.4.1
BASE_IMAGE_UUID = ede31770-e19c-11e5-bb6e-3b7de3cca9ce
BUILDIMAGE_NAME = ${NAME}
BUILDIMAGE_DESC = Triton/Manta component origin image based on multiarch 15.4.x
BUILDIMAGE_PKGSRC = coreutils-8.23nb2 curl-7.51.0 gsed-4.2.2nb4 patch-2.7.5 sudo-1.8.15

include $(TOP)/deps/eng/tools/mk/Makefile.targ
