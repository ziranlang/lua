# Lua agent guide

Lua 5.1 (LuaJIT dialect) written entirely in Ziran: lexer/parser, compiler to
register bytecode, interpreter, mark-and-sweep collector with weak tables and
`__gc`, and the standard libraries. No C code, no native libraries. Built for
Katalis to run Luanti mods from ContentDB. Embedding follows the Lua C API:
a stack, natives as plain Ziran procedures, userdata with metatables,
registry references, yieldable coroutines, and memory/call-depth/instruction
limits for untrusted mods. File and environment access is off until the host
grants it.

## Layout

- `src/vm.zi` — the module, exported as `vm`; import `lua/vm`.
- `tests/` — `vm_test.zi`, `conformance_test.zi`, `katalis_mods_test.zi`, and
  the wasm entry. `docs/` — extra documentation.
- `Makefile` — `test` runs `unit conformance katalis wasm`; `build/` holds
  outputs; an ignored `ziran.local.toml` drops `--locked`.

## Commands

- `make unit` / `make conformance` / `make katalis` — build each suite with
  `--target=c` and run it with display variables removed.
- `make wasm` — Ziran emits C for wasm32, `EMCC` (emsdk) compiles it, and a
  private headless Chromium (fresh profile under `build/`, short `TMPDIR`)
  runs it; needs `EMCC` and `CHROMIUM` available.
- `make test` — all four suites.

## Pins

- Toolchain: `ziran.lock` pins ziran.git
  `5db3d3c39425d5dfe4bfe4a84e6f6e2e5a810ad0`.
- Consumers: `ziran add https://git.waozi.xyz/ziranlang/lua.git`.

## Question -> file

- Embedding API and limits? -> README, `src/vm.zi`.
- What is tested? -> `tests/` and the `Makefile` targets.
- How does the wasm run work? -> `Makefile` (`wasm` target comments).
- Which toolchain? -> `ziran.toml`, `ziran.lock`.
