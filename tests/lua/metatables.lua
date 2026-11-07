-- Metamethods, raw access, protected metatables and weak tables.
local V = {}
V.__index = V
local function vec(x, y) return setmetatable({x = x, y = y}, V) end
V.__add = function(a, b) return vec(a.x + b.x, a.y + b.y) end
V.__sub = function(a, b) return vec(a.x - b.x, a.y - b.y) end
V.__mul = function(a, b)
    if type(a) == "number" then return vec(a * b.x, a * b.y) end
    if type(b) == "number" then return vec(a.x * b, a.y * b) end
    return a.x * b.x + a.y * b.y
end
V.__div = function(a, b) return vec(a.x / b, a.y / b) end
V.__mod = function(a, b) return vec(a.x % b, a.y % b) end
V.__pow = function(a, b) return vec(a.x ^ b, a.y ^ b) end
V.__unm = function(a) return vec(-a.x, -a.y) end
V.__eq = function(a, b) return a.x == b.x and a.y == b.y end
V.__lt = function(a, b) return a.x < b.x end
V.__le = function(a, b) return a.x <= b.x end
V.__concat = function(a, b)
    local sa = type(a) == "table" and ("(" .. a.x .. "," .. a.y .. ")") or a
    local sb = type(b) == "table" and ("(" .. b.x .. "," .. b.y .. ")") or b
    return sa .. sb
end
V.__tostring = function(a) return "vec(" .. a.x .. ", " .. a.y .. ")" end
V.__call = function(self, k) return self[k] end
function V:len() return math.sqrt(self.x * self.x + self.y * self.y) end

local a, b = vec(1, 2), vec(3, 4)
local c = a + b
assert(c.x == 4 and c.y == 6)
assert((b - a).x == 2 and (a * b) == 11 and (2 * a).y == 4 and (a * 3).x == 3)
assert((b / 2).x == 1.5 and (b % 2).x == 1 and (a ^ 2).y == 4 and (-a).x == -1)
assert(a == vec(1, 2) and a ~= b and a < b and a <= b and b > a and not (b <= a))
assert(a .. "!" == "(1,2)!" and "v" .. a == "v(1,2)" and a .. b == "(1,2)(3,4)")
assert(tostring(a) == "vec(1, 2)" and a("x") == 1 and b:len() == 5)

-- __index / __newindex functions and tables, rawget/rawset.
local log = {}
local proxy = setmetatable({}, {
    __index = function(t, k) return k .. "!" end,
    __newindex = function(t, k, v) log[#log + 1] = k; rawset(t, k, v * 2) end,
})
assert(proxy.foo == "foo!")
proxy.n = 5
assert(proxy.n == 10 and log[1] == "n" and rawget(proxy, "n") == 10)
proxy.n = 7
assert(proxy.n == 7 and #log == 1)
assert(rawget(proxy, "missing") == nil)
local base = {greet = function() return "hi" end}
local child = setmetatable({}, {__index = base})
local grandchild = setmetatable({}, {__index = child})
assert(grandchild.greet() == "hi")
local sink = {}
local redirect = setmetatable({}, {__newindex = sink})
redirect.z = 1
assert(rawget(redirect, "z") == nil and sink.z == 1)

-- __eq is only consulted for two tables with the same metamethod.
local e1 = setmetatable({}, {__eq = function() return true end})
assert(e1 ~= 1 and rawequal(e1, e1) and not rawequal(e1, {}))

-- __metatable protection.
local locked = setmetatable({}, {__metatable = "locked"})
assert(getmetatable(locked) == "locked")
assert(not pcall(setmetatable, locked, {}))
assert(getmetatable("abc").__index == string)

-- __tostring and print-like conversion.
assert(tostring(setmetatable({}, {__tostring = function() return "T" end})) == "T")

-- __call with extra arguments.
local callable = setmetatable({}, {__call = function(self, a, b) return a + b end})
assert(callable(2, 3) == 5)
assert(select("#", callable(1, 2)) == 1)

-- __lt fallback for __le (Lua 5.1: not a <= b is not b < a unless __le).
local O = {__lt = function(x, y) return x.v < y.v end}
local o1, o2 = setmetatable({v = 1}, O), setmetatable({v = 2}, O)
assert(o1 < o2 and o2 > o1 and o1 <= o2)

-- Metamethod errors name the operation.
local ok, err = pcall(function() return {} + 1 end)
assert(not ok and err:find("attempt to perform arithmetic on a table value"))
ok, err = pcall(function() return {} < {} end)
assert(not ok and err:find("attempt to compare two table values"))
ok, err = pcall(function() return #nil end)
assert(not ok and err:find("attempt to get length of a nil value"))

-- Weak tables lose collected keys and values.
local weak_k = setmetatable({}, {__mode = "k"})
local weak_v = setmetatable({}, {__mode = "v"})
do
    local key = {}
    weak_k[key] = "value"
    weak_v[1] = {}
    weak_v[2] = "string stays"
end
collectgarbage()
collectgarbage()
assert(next(weak_k) == nil and weak_v[1] == nil and weak_v[2] == "string stays")
local kept = {}
weak_k[kept] = 1
collectgarbage()
assert(weak_k[kept] == 1)

-- __gc on userdata from newproxy.
local collected = 0
do
    local p = newproxy(true)
    getmetatable(p).__gc = function() collected = collected + 1 end
end
collectgarbage()
collectgarbage()
assert(collected == 1)

-- __index on strings via the string metatable.
assert(("abc"):upper() == "ABC" and ("x"):rep(3) == "xxx" and #("abc"):sub(2) == 2)
print("metatables ok")
