# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2020 Joyent, Inc.
#

#
# Makefile for triton-origin-image
#


NAME=triton-origin-image
ENGBLD_REQUIRE	:= $(shell git submodule update --init deps/eng)
include ./deps/eng/tools/mk/Makefile.defs
TOP ?= $(error Unable to access eng.git submodule Makefiles.)

CLEAN_FILES += ./build
DIST_CLEAN_FILES += ./node_modules/ ./build ./bits
NPM = npm
JSON = ./node_modules/.bin/json

#
# Targets
#

$(JSON):
	$(NPM) install

.PHONY: check
check:: check-version

# Ensure CHANGES.md and package.json have the same version.
.PHONY: check-version
check-version:
	@echo version is: $(shell cat package.json | json version)
	[[ `cat package.json | json version` == `grep '^## ' CHANGES.md | head -2 | tail -1 | awk '{print $$2}'` ]]

# This repo doesn't publish to npm, so a 'release' is just a tag.
.PHONY: cutarelease
cutarelease: check-version
	[[ -z `git status --short` ]]  # If this fails, the working dir is dirty.
	@which json 2>/dev/null 1>/dev/null && \
	    ver=$(shell json -f package.json version) && \
	    echo "** Are you sure you want to tag v$$ver?" && \
	    echo "** Enter to continue, Ctrl+C to abort." && \
	    read
	ver=$(shell cat package.json | json version) && \
	    date=$(shell date -u "+%Y-%m-%d") && \
	    git tag -a "v$$ver" -m "version $$ver ($$date)" && \
	    git push --tags origin

#
# Convenience wrappers to run targets for each image without invoking cd yourself
#
triton-origin-multiarch-15.4.1-%:
	@echo '$*'
	cd images/triton-origin-multiarch-15.4.1 && $(MAKE) $*

triton-origin-multiarch-18.1.0-%:
	@echo '$*'
	cd images/triton-origin-multiarch-18.1.0 && $(MAKE) $*

triton-origin-x86_64-18.4.0-%:
	@echo '$*'
	cd images/triton-origin-x86_64-18.4.0 && $(MAKE) $*

triton-origin-x86_64-19.1.0-%:
	@echo '$*'
	cd images/triton-origin-x86_64-19.1.0 && $(MAKE) $*

triton-origin-x86_64-19.2.0-%:
	@echo '$*'
	cd images/triton-origin-x86_64-19.2.0 && $(MAKE) $*

triton-origin-x86_64-19.4.0-%:
	@echo '$*'
	cd images/triton-origin-x86_64-19.4.0 && $(MAKE) $*

#
# Convenience wrapper to run the same target for each image
#
all-%:
	@echo '$*'
	cd images/triton-origin-multiarch-15.4.1 && $(MAKE) $*
	cd images/triton-origin-multiarch-18.1.0 && $(MAKE) $*
	cd images/triton-origin-x86_64-18.4.0 && $(MAKE) $*
	cd images/triton-origin-x86_64-19.1.0 && $(MAKE) $*
	cd images/triton-origin-x86_64-19.2.0 && $(MAKE) $*
	cd images/triton-origin-x86_64-19.4.0 && $(MAKE) $*



include ./deps/eng/tools/mk/Makefile.targ
