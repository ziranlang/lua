# Lua VM embedding API

`#import "lua/vm"` gives a Lua 5.1 virtual machine (LuaJIT dialect) written
in Ziran. The API follows the shape of the Lua C API: a host owns a
`LuaState` record, values move through a stack, and natives are plain Ziran
procedures. Names below are stable; records not listed here (`LuaTable`,
`LuaClosure` and the other object records exported with `LuaState`) are
internal and may change.

## State

```zi
state: LuaState
L := *state
LuaOpen(L)             // false when the record was already open
status := LuaDoString(L, "print('hi')", "=demo")
if status != LUA_OK { message, ok := LuaToString(L, -1) }
LuaClose(L)            // runs pending __gc and host finalizers, frees all
```

`LuaState` is large; keep it in a global or on the heap. One state is one
Lua universe and is not thread-safe. `LuaOpen` loads every standard library
(base, coroutine, string, table, math, os, io, bit, debug).

| Procedure | Meaning |
| --- | --- |
| `LuaSetHost(L, host: *void)`, `LuaHost(L) -> *void` | A host pointer for natives and hooks. |
| `LuaSetPrintSink(L, sink: LuaPrintSink, context: *void)` | `print`, `io.write` and `io.stdout:write` go to `sink(context, text)` instead of standard output. |
| `LuaSetFileRoot(L, path)` | Lets `dofile`, `loadfile`, `io.open` and `io.lines` read files below `path`. Empty (the default) disables Lua-side file access. |
| `LuaAllowEnvironment(L, prefix)` | Lets `os.getenv` read variables whose names start with `prefix`; repeatable. Otherwise `os.getenv` returns nil. |
| `LuaCollectGarbage(L)` | A full collection, from the host or a native (skipped inside a hook). |
| `LuaMemoryUsed(L) -> s64` | Estimated live heap bytes. |

## Status codes and constants

`LUA_OK`, `LUA_YIELD`, `LUA_ERRRUN`, `LUA_ERRSYNTAX`, `LUA_ERRMEM`,
`LUA_ERRERR`, `LUA_ERRFILE`. `LUA_MULTRET` (-1) asks for all results.

Pseudo-indices: `LUA_REGISTRYINDEX`, `LUA_GLOBALSINDEX` (the running
thread's globals), `LUA_ENVIRONINDEX` (the running native's environment) and
`LuaUpvalueIndex(i)` for native closure upvalues.

Type codes from `LuaType`: `LUA_TYPE_NONE` (-1, invalid index), `LUA_TYPE_NIL`,
`LUA_TYPE_BOOLEAN`, `LUA_TYPE_LIGHTUSERDATA`, `LUA_TYPE_NUMBER`,
`LUA_TYPE_STRING`, `LUA_TYPE_TABLE`, `LUA_TYPE_FUNCTION`, `LUA_TYPE_USERDATA`,
`LUA_TYPE_THREAD`. `LuaTypeName(L, type)` gives the Lua name.

## The stack

Index 1 is the first argument of the running native (or the first value the
host pushed), -1 the top. Reading an index past the top gives nil.

| Procedure | Meaning |
| --- | --- |
| `LuaGetTop(L) -> s32` | Number of values. |
| `LuaSetTop(L, index)` | Grow with nils or drop values; `LuaSetTop(L, 0)` clears. |
| `LuaPop(L, n)` | Drop `n` values. |
| `LuaPushValue(L, index)` | Push a copy. |
| `LuaInsert(L, index)` | Move the top value into `index`, shifting up. |
| `LuaRemove(L, index)` | Remove, shifting down. |
| `LuaReplace(L, index)` | Pop the top value into `index`; works with upvalue and global pseudo-indices. |
| `LuaAbsIndex(L, index) -> s32` | A positive index for a relative one. |
| `LuaCheckStack(L, extra) -> bool` | Ensure room for `extra` more values. |

## Values

Push: `LuaPushNil`, `LuaPushBoolean(L, bool)`, `LuaPushNumber(L, float64)`,
`LuaPushInteger(L, s64)`, `LuaPushString(L, string)` (copied and interned),
`LuaPushLightUserdata(L, *void)`, `LuaPushNative(L, fn, name)`,
`LuaPushNativeClosure(L, fn, count, name)`, `LuaPushThreadValue(L) -> bool`
(true on the main thread).

Read: `LuaToNumber -> float64` (0 when not convertible),
`LuaToNumberChecked -> (value, ok)`, `LuaToInteger -> s64` (truncated,
saturated), `LuaToBoolean`, `LuaToString -> (text, ok)`, `LuaToUserdata ->
*void`, `LuaUserdataTag -> s64`, `LuaObjLen -> s64` (raw table
length, string length, the length of a number as text, else 0).

`LuaToString` converts a number in place to a string, as `lua_tolstring`
does. The returned text views interned VM memory: copy it before the value
can be collected (after it leaves the stack and Lua code runs).

Tests: `LuaIsNone`, `LuaIsNil`, `LuaIsNoneOrNil`, `LuaIsBoolean`,
`LuaIsNumber` (numbers and numeric strings), `LuaIsString` (strings and
numbers), `LuaIsTable`, `LuaIsFunction`, `LuaIsNative`, `LuaIsUserdata`
(full or light). Comparison: `LuaRawEqual(L, a, b) -> bool`,
`LuaEqual(L, a, b) -> (equal, ok)` and `LuaLessThan(L, a, b) -> (less, ok)`
run metamethods.

## Tables

| Procedure | Meaning |
| --- | --- |
| `LuaNewTable(L)`, `LuaCreateTable(L, narr, nrec)` | Push a new table, optionally presized. |
| `LuaGetField(L, index, name) -> bool` | Push `t[name]` (metamethods). |
| `LuaSetField(L, index, name) -> bool` | `t[name] = pop()` (metamethods). |
| `LuaGetTable(L, index) -> bool` | Pop a key, push `t[key]`. |
| `LuaSetTable(L, index) -> bool` | Pop value and key, `t[key] = value`. |
| `LuaGetGlobal(L, name)`, `LuaSetGlobal(L, name)` | The same on the globals. |
| `LuaRawGet(L, index)`, `LuaRawSet(L, index) -> bool` | Without metamethods; `LuaRawSet` is false for a nil or NaN key. |
| `LuaRawGetI(L, index, n)`, `LuaRawSetI(L, index, n)` | Integer keys, raw. |
| `LuaNext(L, index) -> s32` | Pop a key, push the next key and value: 1, or 0 at the end, or -1 for an invalid key. |

Iterate like the C API:

```zi
LuaPushNil(L)
while LuaNext(L, table) == 1 {
    // key at -2, value at -1
    LuaPop(L, 1)
}
```

The bool results are false when a metamethod raised an error. Inside a
native, return `LUA_NATIVE_ERROR` then; from the host, wrap the work in a
native and call it with `LuaPCall` when metamethods can fail.

## Metatables, userdata and environments

| Procedure | Meaning |
| --- | --- |
| `LuaGetMetatable(L, index) -> bool` | Push the metatable; false (nothing pushed) without one. |
| `LuaSetMetatable(L, index) -> bool` | Pop a table or nil into the value's metatable (tables, userdata, or the shared one of a basic type). |
| `LuaNewMetatable(L, name) -> bool` | Push `registry[name]`, creating it; false when it existed. |
| `LuaGetRegistryMetatable(L, name)` | Push `registry[name]`. |
| `LuaNewUserdata(L, data: *void, tag: s64)` | Push a full userdata wrapping host data; `tag` names the host type. |
| `LuaNewUserdataFinalized(L, data, tag, finalizer: LuaFinalizer)` | The same; `finalizer(L, data, tag)` runs when it is collected or the state closes, after any `__gc`. |
| `LuaTestUserdata(L, index, name) -> *void` | The data of a userdata whose metatable is `registry[name]`, else null. |
| `LuaGetFenv(L, index)`, `LuaSetFenv(L, index) -> bool` | A function's, userdata's or thread's environment table. |

The VM never owns host data: a userdata holds the pointer, and the host
frees it in the finalizer.

## Natives

```zi
LuaNative :: #type (L: *LuaState) -> s32;
```

A native reads its arguments at 1..`LuaGetTop(L)`, pushes results and
returns how many (the top values are taken). It returns `LUA_NATIVE_ERROR`
to raise the pending error, or `LuaYield(L, n)` to yield.

```zi
Add :: (L: *LuaState) -> s32 {
    a, ok1 := LuaCheckNumber(L, 1)
    if !ok1 { return LUA_NATIVE_ERROR }
    b, ok2 := LuaCheckNumber(L, 2)
    if !ok2 { return LUA_NATIVE_ERROR }
    LuaPushNumber(L, a + b)
    return 1
}

LuaRegister(L, "add", Add)            // globals.add
LuaNewTable(L)
LuaSetNative(L, -1, "add", Add)       // t.add
LuaSetGlobal(L, "host")
```

Argument checks set the standard error and return `ok = false`:
`LuaCheckNumber`, `LuaCheckInteger`, `LuaCheckString` (numbers convert),
`LuaCheckTable -> bool`, `LuaCheckAny -> bool`, and `LuaOptNumber`,
`LuaOptInteger`, `LuaOptString` with a fallback for nil or missing.

Raising errors (each returns `LUA_NATIVE_ERROR`):

- `LuaErrorText(L, message)`: "chunk:line: message" at the Lua caller.
- `LuaArgError(L, n, message)`: "bad argument #n to 'name' (message)".
- `LuaTypeError(L, n, expected)`: "... (expected expected, got type)".
- `LuaRaiseError(L)`: raise the value on top of the stack as is.

`LuaPushNativeClosure(L, fn, count, name)` takes the top `count` values as
upvalues; read them with `LuaPushValue(L, LuaUpvalueIndex(i))` and write them
with `LuaReplace(L, LuaUpvalueIndex(i))`.

## Loading and calling

| Procedure | Meaning |
| --- | --- |
| `LuaLoadBuffer(L, text, chunkname) -> s32` | Compile and push a function, or push the message (`LUA_ERRSYNTAX`). |
| `LuaLoadString(L, text) -> s32` | `LuaLoadBuffer` with the text as its name. |
| `LuaLoadFile(L, path) -> s32` | Load a host file (not limited by the file root); `LUA_ERRFILE` when unreadable. |
| `LuaDoString(L, text, chunkname) -> s32` | Load and run with a traceback handler; results stay on the stack. |
| `LuaDoFile(L, path) -> s32` | The same for a host file. |
| `LuaCall(L, nargs, want) -> bool` | Unprotected call of the function below `nargs` arguments. Inside a native, return `LUA_NATIVE_ERROR` when false. |
| `LuaPCall(L, nargs, want, handler) -> s32` | Protected call; `handler` is a stack index of a message handler or 0. On error the message replaces the function and arguments. |
| `LuaTraceback(L, message, level)` | Push "message\nstack traceback:\n...". |

Chunk names follow Lua: "@file.lua" prints as `file.lua:3:`, "=name" as
`name:3:`, anything else as `[string "..."]:3:`. Lua errors carry a
position; `error(value)` with a non-string keeps the value as is.

Call `LuaPCall` or `LuaDoString` from the host. A host call outside any
protected call leaves its error pending with no handler to receive it.

## Registry references

`LuaRef(L) -> s32` pops a value into the registry and returns a handle
(`LUA_REFNIL` for nil); `LuaPushRef(L, ref)` pushes it back; `LuaUnref(L,
ref)` releases it. A referenced value stays alive.

## Coroutines

`LuaNewThread(L)` pops a function and pushes a coroutine running it.
`LuaResume(L, index, nargs) -> (status, count)` resumes the coroutine at
`index` with the top `nargs` values; its yielded or returned values (or the
error message) replace them. The status is `LUA_YIELD`, `LUA_OK` (finished)
or an error.

A native yields with `return LuaYield(L, n)`, yielding its top `n` values;
the values passed to the next resume become that native call's results.

```zi
Wait :: (L: *LuaState) -> s32 { return LuaYield(L, LuaGetTop(L)) }
```

As in Lua 5.1, yielding across a `pcall`, a metamethod or a native that
called back into Lua raises "attempt to yield across metamethod/C-call
boundary".

## Limits and hooks

```zi
LuaLimits :: struct {
    max_memory: s64        // estimated live bytes; 0 = unlimited
    max_native_depth: s32  // nested native re-entry (default 190)
    max_frames: s32        // Lua call frames per thread (default 200000)
}
limits := LuaGetLimits(L)
limits.max_memory = 64 * 1048576
LuaSetLimits(L, limits)
```

Going over `max_memory` raises "not enough memory" in the running Lua code
after a collection fails to free enough. Deep recursion raises "stack
overflow".

`LuaSetHook(L, hook: LuaHook, count)` calls `hook(L) -> bool` every `count`
checkpoints (Lua calls and loop back-edges). Returning false raises an error
in the running Lua code: "instruction limit exceeded", or the message set
with `LuaSetHookMessage(L, message)` inside the hook. `LuaClearHook(L)`
removes it. Use it to stop runaway mod code.

## Supported Lua

Lua 5.1 semantics with LuaJIT's extensions: `goto` and labels, `\x`, `\z`
and `\u{...}` escapes, `bit`, `math.log(x, base)`, `string.format("%a")`, `load` with a
reader function, `newproxy`.

- Base: `assert collectgarbage dofile error gcinfo getfenv getmetatable ipairs
  load loadfile loadstring newproxy next pairs pcall print rawequal rawget
  rawset require select setfenv setmetatable tonumber tostring type unpack
  xpcall _G _VERSION`. `require` resolves through `package.loaded` and
  `package.preload` only.
- `coroutine`: `create resume yield status running wrap`.
- `string`: `byte char dump find format gfind gmatch gsub len lower match rep
  reverse sub upper`, with Lua patterns, and strings indexable as
  `("x"):upper()`. `string.dump` raises an error.
- `table`: `concat foreach foreachi getn insert maxn remove setn sort`.
- `math`: all of Lua 5.1, plus `math.mod`.
- `bit`: `tobit tohex bnot band bor bxor lshift rshift arshift rol ror bswap`.
- `os`: `clock date difftime getenv time`. No `execute`, `exit`, `remove`,
  `rename` or `tmpname`.
- `io`: `write`, `read` (always nil), `open` and `lines` (read-only below the
  file root), `type`, `stdout`, `stderr`. Files support `read lines seek
  close`.
- `debug`: `traceback getinfo getlocal setlocal getupvalue setupvalue
  getmetatable setmetatable getregistry getfenv setfenv`; `sethook` and
  `gethook` accept calls but install nothing.
