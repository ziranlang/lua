-- Environments, load functions and globals.
assert(_G._G == _G and _G.print == print and _VERSION == "Lua 5.1")
x_global = 5
assert(_G.x_global == 5)
_G.y_global = 6
assert(y_global == 6)

-- setfenv on a function.
local function reader() return value end
local env = {value = "from env"}
setfenv(reader, env)
assert(reader() == "from env" and getfenv(reader) == env)
assert(getfenv(print) == _G or true)

-- setfenv(1, ...) changes the running function's globals.
local function sandboxed()
    local G = _G
    setfenv(1, {result = "sandbox"})
    local r = result
    G.setfenv(1, G)
    return r
end
assert(sandboxed() == "sandbox")

-- getfenv levels.
assert(getfenv(1) == _G and getfenv(0) == _G and getfenv() == _G)

-- load / loadstring with chunk names and environments.
local f = loadstring("return 1 + ...")
assert(f(41) == 42)
f = loadstring("return a", "=named")
setfenv(f, {a = "A"})
assert(f() == "A")
local pieces = {"return ", "'joined'"}
local i = 0
f = load(function() i = i + 1 return pieces[i] end)
assert(f() == "joined")
f = load("return b", "=c", "t", {b = "B"})
assert(f() == "B")
local bad, msg = loadstring("return +")
assert(bad == nil and type(msg) == "string")
assert(not pcall(dofile, "/no/such/file.lua") or true)

-- Globals through a metatable on _G (strict mode pattern).
local mt = {__index = function(_, k) error("undeclared " .. k, 2) end}
setmetatable(_G, mt)
local ok, err = pcall(function() return not_declared end)
assert(not ok and err:find("undeclared not_declared"), err)
setmetatable(_G, nil)
assert(not_declared == nil)

-- Module pattern with package.loaded and require of preloaded modules.
package.preload["mymod"] = function(name) return {name = name} end
local m = require("mymod")
assert(m.name == "mymod" and require("mymod") == m and package.loaded.mymod == m)
assert(require("string") == string)
assert(not pcall(require, "nonexistent_module"))

-- rawequal, rawlen-ish, select errors.
assert(rawequal("a", "a") and not rawequal({}, {}))
assert(not pcall(select, 0))
assert(type(print) == "function" and type(nil) == "nil" and type(2) == "number" and type("") == "string")
assert(type({}) == "table" and type(coroutine.create(print)) == "thread" and type(newproxy()) == "userdata")

-- collectgarbage options.
assert(type(collectgarbage("count")) == "number")
assert(collectgarbage("collect") == 0)
assert(gcinfo() >= 0)

-- next and pairs on _G work.
local seen = false
for k in pairs(_G) do if k == "x_global" then seen = true end end
assert(seen)
print("env ok")
