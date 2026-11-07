-- Coroutines: resume/yield value passing, status, wrap and errors.
local co = coroutine.create(function(a, b)
    assert(coroutine.status(coroutine.running()) == "running")
    local c = coroutine.yield(a + b)
    local d, e = coroutine.yield(c * 2)
    return d + e, "end"
end)
assert(coroutine.status(co) == "suspended")
local ok, v = coroutine.resume(co, 1, 2)
assert(ok and v == 3)
ok, v = coroutine.resume(co, 10)
assert(ok and v == 20)
local ok2, sum, tag = coroutine.resume(co, 3, 4)
assert(ok2 and sum == 7 and tag == "end" and coroutine.status(co) == "dead")
ok, v = coroutine.resume(co)
assert(not ok and v == "cannot resume dead coroutine")

-- Generators with wrap.
local function range(n)
    return coroutine.wrap(function()
        for i = 1, n do coroutine.yield(i) end
    end)
end
local total = 0
for i in range(10) do total = total + i end
assert(total == 55)

-- Yield from nested Lua calls.
local function inner() coroutine.yield("inner") return "back" end
co = coroutine.create(function() local r = inner(); coroutine.yield(r); return "done" end)
assert(select(2, coroutine.resume(co)) == "inner")
assert(select(2, coroutine.resume(co)) == "back")
assert(select(2, coroutine.resume(co)) == "done")

-- Errors inside coroutines.
co = coroutine.create(function() error("oops") end)
ok, v = coroutine.resume(co)
assert(not ok and v:find("oops") and coroutine.status(co) == "dead")
local w = coroutine.wrap(function() error("wrapped", 0) end)
ok, v = pcall(w)
assert(not ok and v == "wrapped")

-- yield outside a coroutine fails; running is nil on the main thread.
assert(not pcall(coroutine.yield, 1))
assert(coroutine.running() == nil)

-- A coroutine resuming another.
local producer = coroutine.wrap(function() for i = 1, 3 do coroutine.yield(i) end end)
local consumer = coroutine.create(function()
    local got = {}
    for _ = 1, 3 do got[#got + 1] = producer() end
    coroutine.yield(table.concat(got, ","))
end)
assert(select(2, coroutine.resume(consumer)) == "1,2,3")
local outer
outer = coroutine.create(function()
    local inner_co = coroutine.create(function()
        assert(coroutine.status(outer) == "normal")
        coroutine.yield()
    end)
    coroutine.resume(inner_co)
    return "ok"
end)
assert(select(2, coroutine.resume(outer)) == "ok")

-- Passing many values and nil through yield.
co = coroutine.create(function(...) local n = select("#", ...) coroutine.yield(n, ...) end)
local res = {coroutine.resume(co, nil, 2, nil)}
assert(res[1] == true and res[2] == 3 and res[4] == 2)

-- Many coroutines are collected.
for i = 1, 1000 do
    local c = coroutine.wrap(function(x) coroutine.yield(x * 2) end)
    assert(c(i) == i * 2)
end
collectgarbage()

-- Body that is coroutine.yield itself.
co = coroutine.create(coroutine.yield)
ok, v = coroutine.resume(co, "a")
assert(ok and v == "a")
ok, v = coroutine.resume(co, "b")
assert(ok and v == "b" and coroutine.status(co) == "dead")

-- Generic for over a stateful iterator inside a coroutine.
co = coroutine.wrap(function()
    for k, v in pairs({x = 1}) do coroutine.yield(k, v) end
    return "fin"
end)
local k1, v1 = co()
assert(k1 == "x" and v1 == 1 and co() == "fin")
print("coroutines ok")
