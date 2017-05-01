#
# Copyright (c) 2017, Joyent, Inc.
#
# Makefile for triton-origin-image
#

NPM = npm
JSON = ./node_modules/.bin/json

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

build/image-0-stamp: build/buildinfo.json images.json
	./tools/build-images.sh -b build/buildinfo.json -i images.json
	touch $@

publish:
	echo "not yet implemented (TODO)"
	false

.PHONY: check
check:
	@echo "check ok"

.PHONY: clean
clean:
	rm -rf build

.PHONY: distclean
distclean: clean
	rm -rf node_modules
