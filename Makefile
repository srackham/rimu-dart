# rimu-dart Makefile

# Set defaults (see http://clarkgrubb.com/makefile-style-guide#prologue)
MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := test
.DELETE_ON_ERROR:
.SUFFIXES:
.ONESHELL:

.PHONY: test
test:
	pub run test test/rimu_dart_test.dart

build/rimuc: bin/rimuc.dart
	dart2native bin/rimuc.dart -o build/rimuc

.PHONY: build
build: build/rimuc