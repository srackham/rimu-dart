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

RIMU_SRC = $(shell find lib -type f -name '*.dart')
RIMUC_SRC = bin/rimuc.dart
RESOURCES_SRC = lib/src/resources.dart
TEST_SRC = test/*.dart
RIMUC_EXE = build/rimuc
TEST_FIXTURES = test/fixtures/* test/*.json
RESOURCE_FILES = lib/resources/*

.PHONY: test
test: $(RIMUC_EXE) $(RESOURCES_SRC)
	dart test $(TEST_SRC)

.PHONY: build
build: $(RIMUC_EXE)

$(RIMUC_EXE): $(RIMUC_SRC) $(RIMU_SRC)
	if [ ! -d build ]; then
		mkdir build
	fi
	echo "Building executable $@"
	dart compile exe $< -o $@

# Build resources.dart containing a Map<filename,contents> of rimuc resource files.
$(RESOURCES_SRC): $(RESOURCE_FILES)
	echo "Building resources $@"
	echo "// Generated automatically from resource files. Do not edit." > $@
	echo "Map<String, String> resources = {" >> $@
	for f in $^; do
		echo -n "  '$$(basename $$f)': " >> $@
		echo "r'''$$(cat $$f)'''," >> $@
	done
	echo "};" >> $@

.PHONY: tag
# Tag the latest commit with the VERS environment variable e.g. make tag VERS=1.0.0
tag: test
	[[ ! $$VERS =~ ^[0-9]+\.[0-9]+\.[0-9]+$$ ]] && echo "error: illegal VERS=$$VERS " && exit 1
	tag=v$(VERS)
	echo tag: $$tag
	git tag -a -m $$tag $$tag

.PHONY: push
push:
	git push -u --tags origin master
