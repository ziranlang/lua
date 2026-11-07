-- Expressions, control flow, closures, varargs, multiple results, tail calls.
assert(1 + 2 * 3 == 7 and (1 + 2) * 3 == 9)
assert(7 % 3 == 1 and -7 % 3 == 2 and 7 % -3 == -2 and 5.5 % 2 == 1.5)
assert(2 ^ 10 == 1024 and 2 ^ 0.5 == math.sqrt(2))
assert(7 / 2 == 3.5 and -(-3) == 3)
assert("10" + 5 == 15 and "3" * "4" == 12 and 10 .. 20 == "1020")
assert(0x10 == 16 and 0xff == 255 and 1e2 == 100 and .5 == 0.5 and 3. == 3)
assert(tostring(1e15) == "1e+15" and tostring(123456789012) == "123456789012")
assert(tostring(0.1) == "0.1" and tostring(-0.0) == "-0" and tostring(1/0) == "inf" and tostring(-1/0) == "-inf")
assert(tostring(2^53) == "9.007199254741e+15" and tostring(3.14159265358979) == "3.1415926535898")
assert(not nil and not false and 0 and "" and true)
assert((nil or 5) == 5 and (false and 1) == false and (1 and 2) == 2)
assert(1 < 2 and "a" < "b" and "abc" < "abd" and "" < "a" and not ("b" < "a"))
assert(1 == 1.0 and "1" ~= 1 and {} ~= {})
assert(#"hello" == 5 and #{1, 2, 3} == 3)

local s = 0
for i = 1, 10 do s = s + i end
assert(s == 55)
s = 0
for i = 10, 1, -2 do s = s + i end
assert(s == 30)
s = 0
for i = 1, 0 do s = s + 1 end
assert(s == 0)
for i = 0.5, 1.5, 0.5 do s = s + i end
assert(s == 3)
local n = 0
while n < 5 do n = n + 1 end
assert(n == 5)
repeat local k = n; n = n - 1 until k <= 2
assert(n == 1)
for i = 1, 100 do if i == 7 then n = i break end end
assert(n == 7)

-- Each iteration gets a fresh local; closures capture it.
local fns = {}
for i = 1, 3 do fns[i] = function() return i end end
assert(fns[1]() == 1 and fns[3]() == 3)
local function counter()
    local c = 0
    return function() c = c + 1; return c end, function() return c end
end
local inc, get = counter()
inc(); inc()
assert(get() == 2)

-- Shared upvalues between sibling closures and nested functions.
local function outer()
    local x = 1
    local function a() x = x + 1 end
    local function b() return function() return x end end
    return a, b()
end
local a, b = outer()
a(); a()
assert(b() == 3)

-- Varargs and multiple results.
local function va(...)
    local t = {...}
    return select("#", ...), #t, ...
end
local c1, c2, x1, x2 = va(10, nil, 30)
assert(c1 == 3 and x1 == 10 and x2 == nil)
assert(select(2, "a", "b", "c") == "b" and select(-1, "a", "b", "c") == "c")
local function mr() return 1, 2, 3 end
local t = {mr(), mr()}
assert(#t == 4 and t[4] == 3)
t = {mr(), (mr())}
assert(#t == 2)
assert(select("#", mr()) == 3 and select("#", (mr())) == 1)
local function pass(...) return ... end
assert(select("#", pass(nil, nil)) == 2)
local p, q, r = pass(1)
assert(p == 1 and q == nil and r == nil)
assert(math.max(mr()) == 3)
local function varg_arg(...) local a, b = ... return a, b, arg end
local va1, va2, va3 = varg_arg(4, 5)
assert(va1 == 4 and va2 == 5 and va3 == nil)

-- Proper tail calls do not grow the stack.
local function loop(k) if k == 0 then return "done" end return loop(k - 1) end
assert(loop(200000) == "done")

-- Recursion.
local function fib(k) if k < 2 then return k end return fib(k - 1) + fib(k - 2) end
assert(fib(20) == 6765)

-- Methods and the colon syntax.
local obj = {v = 2}
function obj:twice(y) return self.v * y end
function obj.static(y) return y + 1 end
assert(obj:twice(5) == 10 and obj.static(1) == 2)
local deep = {a = {b = {}}}
function deep.a.b.f() return "deep" end
assert(deep.a.b.f() == "deep")

-- String escapes and long strings.
assert("\65\066\x43" == "ABC")
assert("a\tb\n" == "a" .. string.char(9) .. "b" .. string.char(10))
assert([[
line]] == "line" and [==[a]]b]==] == "a]]b")
assert("a\z   
   b" == "ab")

-- goto (LuaJIT extension).
local g = 0
::top::
g = g + 1
if g < 3 then goto top end
assert(g == 3)
for i = 1, 3 do
    for j = 1, 3 do
        if j == 2 then goto continue end
        g = g + 1
        ::continue::
    end
end
assert(g == 9)

-- Long concatenation chains and numbers in strings.
local parts = {}
for i = 1, 100 do parts[#parts + 1] = i end
assert(#table.concat(parts, ",") == 291)
assert(1 .. "" == "1" and 1.5 .. "" == "1.5" and -2 .. "" == "-2")

-- Integer-valued floats print without a decimal point.
assert(tostring(3.0) == "3" and tostring(1e14) == "1e+14" and tostring(-12.25) == "-12.25")
print("basics ok")
