#
# Copyright (c) 2017, Joyent, Inc.
#
# Makefile for triton-origin-image
#

NPM = npm
CREATE_IMAGE = ./create-image.sh
CONFIG = ./data.json

# Should this default to /Joyent_Dev/stor/builds/.... ?
MANTA_PATH =

# -------

#
# Targets
#
.PHONY: all image

all: npm-0-stamp image-0-stamp

npm-0-stamp:
	$(NPM) install
	touch $@

image-0-stamp: npm-0-stamp
	$(CREATE_IMAGE) -f $(CONFIG) $(MANTA_PATH)
	touch $@

clean:
	rm -f npm-0-stamp image-0-stamp
