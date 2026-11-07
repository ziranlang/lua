ZIRAN ?= ziran
LOCKED := $(if $(wildcard ziran.local.toml),,--locked)
BUILD := $(ZIRAN) build --project $(LOCKED) --target=c --exe -o build/tests
RUN := env -u DISPLAY -u WAYLAND_DISPLAY -u XAUTHORITY -u DBUS_SESSION_BUS_ADDRESS

# The wasm32 check: Ziran writes the C for the web platform, Emscripten from
# emsdk compiles it (zi2c's own link passes `-x none`, which emcc misreads),
# and a private headless Chromium runs it (fresh profile under build/, no
# display). Chromium's socket path must stay short, so its TMPDIR is build/t.
EMCC ?= $(HOME)/emsdk/upstream/emscripten/emcc
CHROMIUM ?= chromium
# Compiler runs outside ziran go through the shared build queue when present.
QUEUE := $(if $(shell command -v build-queue),build-queue --,)
WASM_LDFLAGS := -sSINGLE_FILE=1 -sWASM_ASYNC_COMPILATION=0 -sALLOW_MEMORY_GROWTH=1 -sENVIRONMENT=web -sSTACK_SIZE=1048576

.PHONY: test unit conformance katalis wasm
test: unit conformance katalis wasm

unit:
	$(BUILD) --entry vm_test:Main tests/vm_test.zi
	$(RUN) build/tests/vm_test

conformance:
	$(BUILD) --entry conformance_test:Main tests/conformance_test.zi
	$(RUN) build/tests/conformance_test

katalis:
	$(BUILD) --entry katalis_mods_test:Main tests/katalis_mods_test.zi
	$(RUN) build/tests/katalis_mods_test

wasm:
	@if ! test -x "$(EMCC)" || ! command -v "$(CHROMIUM)" >/dev/null; then \
		echo "SKIP wasm32: needs EMCC ($(EMCC)) and CHROMIUM ($(CHROMIUM))"; exit 0; fi; \
	set -e; \
	rm -rf build/wasm build/t; mkdir -p build/wasm build/t; \
	env CFLAGS=-O0 $(ZIRAN) build --project $(LOCKED) --target=c --define PLATFORM_WEB --exe -o build/wasm --entry wasm_test:Main tests/wasm_test.zi; \
	$(ZIRAN) compile-commands --project -o build/wasm/commands.json build/wasm; \
	include=$$(sed -n 's/^ *"-I\(.*\)",*$$/\1/p' build/wasm/commands.json | grep -v '/build/wasm$$' | head -1); \
	$(QUEUE) "$(EMCC)" -std=c99 -O2 -w -I build/wasm -I "$$include" build/wasm/*.c -lm $(WASM_LDFLAGS) -o build/wasm/wasm_test.js; \
	cp tests/wasm_page.html build/wasm/index.html; \
	$(RUN) TMPDIR="$(CURDIR)/build/t" timeout 120 "$(CHROMIUM)" --headless --no-first-run \
		--no-default-browser-check --disable-extensions --use-gl=disabled --disable-gpu \
		--user-data-dir="$(CURDIR)/build/t/profile" \
		--dump-dom "file://$(CURDIR)/build/wasm/index.html" > build/wasm/page.txt 2> build/wasm/chromium.log || true; \
	rm -rf build/t; \
	if grep -q 'wasm32 strings ok' build/wasm/page.txt; then echo "wasm32 strings ok"; \
	else echo "FAIL wasm32:"; cat build/wasm/page.txt; tail -5 build/wasm/chromium.log; exit 1; fi
