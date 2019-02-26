#
# Copyright (c) 2017, Joyent, Inc.
#
# Makefile for triton-origin-image
#


NAME=triton-origin-image
ENGBLD_REQUIRE	:= $(shell git submodule update --init deps/eng)
include ./deps/eng/tools/mk/Makefile.defs
TOP ?= $(error Unable to access eng.git submodule Makefiles.)

CLEAN_FILES += ./build
DIST_CLEAN_FILES += ./node_modules/ ./build
NPM = npm
JSON = ./node_modules/.bin/json


# TODO: just include
# Gather build info (based on
# https://github.com/joyent/eng/blob/master/tools/mk/Makefile.defs#L34-L48)
_AWK := $(shell (which gawk >/dev/null && echo gawk) \
	|| (which nawk >/dev/null && echo nawk) \
	|| echo awk)
BRANCH := $(shell git symbolic-ref HEAD | $(_AWK) -F/ '{print $$3}')
ifeq ($(TIMESTAMP),)
	TIMESTAMP := $(shell date -u "+%Y%m%dT%H%M%SZ")
endif
GITHASH := $(shell git log -1 --pretty='%H')


#
# Targets
#

.PHONY: all
all: build/buildinfo.json build/image-0-stamp

$(JSON):
	$(NPM) install

build/buildinfo.json: | $(JSON)
	mkdir -p build/
	echo '{}' \
		| $(JSON) -e "this.branch='$(BRANCH)'" \
			-e "this.timestamp='$(TIMESTAMP)'" \
			-e "this.git='$(GITHASH)'" \
		> $@

.PHONY: buildinfo
buildinfo: build/buildinfo.json

.PHONY: images
images: build/image-0-stamp

# Build all images spec'd in images.json and upload to Manta builds area,
# e.g. /Joyent_Dev/public/builds/triton-origin-image/...
build/image-0-stamp: build/buildinfo.json images.json
	./tools/build-images.sh -b build/buildinfo.json -i images.json
	touch $@

# Publish the built images (identified via "buildinfo.json") to
# updates.joyent.com.
publish: build/buildinfo.json
	./tools/publish-images.sh -b build/buildinfo.json


.PHONY: check
check:: check-version
	@echo "check ok"

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



#.PHONY: all-images
#all-images: triton-origin-multiarch-15.4.1


.PHONY: buildimage-all
buildimage-all:
	cd images/triton-origin-multiarch-15.4.1 && $(MAKE) buildimage
	cd images/triton-origin-multiarch-15.4.1 && $(MAKE) buildimage




include ./deps/eng/tools/mk/Makefile.targ
