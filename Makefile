# rimu-dart Makefile

# Set defaults (see http://clarkgrubb.com/makefile-style-guide#prologue)
MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := test
.DELETE_ON_ERROR:
.SUFFIXES:
.ONESHELL:
.SILENT:

.PHONY: test
test: bin/resources.dart
	pub run test test/rimu_test.dart

build/rimuc: bin/rimuc.dart bin/resources.dart
	echo "Building executable $@"
	dart2native $< -o $@

.PHONY: build
build: build/rimuc

# .PHONY: resources
# resources:
bin/resources.dart: bin/resources/*
	# Build resources.dart containing Map<filename,contents> of rimuc resource files.
	echo "Building resources $@"
	echo "// Generated automatically from resource files. Do not edit." > $@
	echo "Map<String, String> resources = {" >> $@
	for f in $^; do
		echo "'$$(basename $$f)':" >> $@
		echo "r'''$$(cat $$f)'''," >> $@
	done
	echo "};" >> $@
