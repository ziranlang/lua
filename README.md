# Lua

Lua is a [Ziran](https://github.com/ziranlang/ziran) package that runs Lua
5.1 code in the LuaJIT dialect. Everything is written in Ziran, with no C
code and no native libraries: the lexer and parser, a compiler to register
bytecode, the interpreter, a mark-and-sweep collector with weak tables and
`__gc`, and the standard libraries. It was written so that
[Katalis](https://github.com/waozixyz/katalis) can run Luanti mods from
ContentDB.

The embedding API follows the Lua C API: a stack, natives as plain Ziran
procedures, userdata with metatables, registry references, coroutines a
native can yield from, and limits on memory, call depth and instruction
count for running untrusted mods. File and environment access is off until
the host grants it.

## Use it

```sh
ziran add https://github.com/ziranlang/lua.git
```

```zi
#import "lua/vm"

state: LuaState;

Add :: (L: *LuaState) -> s32 {
    a, ok1 := LuaCheckNumber(L, 1)
    if !ok1 { return LUA_NATIVE_ERROR }
    b, ok2 := LuaCheckNumber(L, 2)
    if !ok2 { return LUA_NATIVE_ERROR }
    LuaPushNumber(L, a + b)
    return 1
}

Run :: () -> bool {
    L := *state
    LuaOpen(L)
    LuaRegister(L, "add", Add)
    status := LuaDoString(L, "print(add(1, 2))", "=example")
    if status != LUA_OK {
        message, ok := LuaToString(L, -1)
        print("%\n", message)
    }
    LuaClose(L)
    return status == LUA_OK
}
```

[docs/API.md](docs/API.md) describes the whole API and what each library
supports.

## Check it

```sh
make test
```

This runs the API unit tests, the Lua scripts in `tests/lua`, and loads
every `.lua` file of the Katalis mods (set `KATALIS_MODS` to another
folder; it is skipped when missing).
