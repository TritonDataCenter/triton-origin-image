# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2022 Joyent, Inc.
#

NAME=triton-origin-x86_64-21.4.0
TOP=$(shell git rev-parse --show-toplevel)

include $(TOP)/Makefile.origin.defs
include $(TOP)/deps/eng/tools/mk/Makefile.defs

BUILDIMAGE_DO_PKGSRC_UPGRADE:=true

# minimal-64-lts@21.4.0
BASE_IMAGE_UUID = a7199134-7e94-11ec-be67-db6f482136c2
BUILDIMAGE_NAME = ${NAME}
BUILDIMAGE_DESC = Triton/Manta component origin image based on x86_64 21.4.0
BUILDIMAGE_PKGSRC = coreutils curl gsed patch sudo

include $(TOP)/deps/eng/tools/mk/Makefile.targ
