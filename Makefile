ZIRAN ?= ziran
LOCKED := $(if $(wildcard ziran.local.toml),,--locked)
BUILD := $(ZIRAN) build --project $(LOCKED) --target=c --exe -o build/tests
RUN := env -u DISPLAY -u WAYLAND_DISPLAY

.PHONY: test unit conformance katalis
test: unit conformance katalis

unit:
	$(BUILD) --entry vm_test:Main tests/vm_test.zi
	$(RUN) build/tests/vm_test

conformance:
	$(BUILD) --entry conformance_test:Main tests/conformance_test.zi
	$(RUN) build/tests/conformance_test

katalis:
	$(BUILD) --entry katalis_mods_test:Main tests/katalis_mods_test.zi
	$(RUN) build/tests/katalis_mods_test
