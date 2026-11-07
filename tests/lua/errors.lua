-- error, pcall, xpcall, positions and messages.
local ok, err = pcall(error, "boom")
assert(not ok and err == "boom")
ok, err = pcall(function() error("where") end)
assert(not ok and err:match("^errors.lua:%d+: where$"), err)
ok, err = pcall(function() error("nowhere", 0) end)
assert(err == "nowhere")
local function lvl2() error("caller", 2) end
ok, err = pcall(function()
    lvl2() -- this line is blamed
end)
assert(err:match("^errors.lua:%d+: caller$"), err)
local obj = {code = 7}
ok, err = pcall(error, obj)
assert(err == obj)
ok, err = pcall(error)
assert(not ok and err == nil)
assert(select("#", pcall(function() return 1, 2, 3 end)) == 4)
local r1, r2 = pcall(function(a, b) return a + b end, 2, 3)
assert(r1 == true and r2 == 5)

-- Runtime error messages name the variable.
ok, err = pcall(function() local t = nil; return t.x end)
assert(err:find("attempt to index local 't' %(a nil value%)"), err)
ok, err = pcall(function() return undefined_global.x end)
assert(err:find("attempt to index global 'undefined_global' %(a nil value%)"), err)
ok, err = pcall(function() local t = {} return t.a.b end)
assert(err:find("attempt to index field 'a' %(a nil value%)"), err)
ok, err = pcall(function() return nil + 1 end)
assert(err:find("attempt to perform arithmetic on a nil value"), err)
ok, err = pcall(function() local s = "x" return s + 1 end)
assert(err:find("attempt to perform arithmetic on local 's' %(a string value%)"), err)
ok, err = pcall(function() missing_fn() end)
assert(err:find("attempt to call global 'missing_fn' %(a nil value%)"), err)
ok, err = pcall(function() local t = {} t:nomethod() end)
assert(err:find("attempt to call method 'nomethod' %(a nil value%)"), err)
ok, err = pcall(function() return "a" .. {} end)
assert(err:find("attempt to concatenate a table value"), err)
ok, err = pcall(function() return 1 < "2" end)
assert(err:find("attempt to compare number with string"), err)
ok, err = pcall(string.rep)
assert(err:find("bad argument #1 to 'rep' %(string expected, got no value%)"), err)
ok, err = pcall(("x").rep, "x", {})
assert(err:find("bad argument #2 to 'rep'"), err)
ok, err = pcall(setmetatable, 1, {})
assert(not ok)

-- xpcall runs the handler at the error point.
local trace
ok, err = xpcall(function() error("deep") end, function(m) trace = debug.traceback(m, 2); return "handled: " .. m end)
assert(not ok and err:match("^handled: errors.lua:%d+: deep$"), err)
assert(trace:find("stack traceback:"), trace)
ok, err = xpcall(function() return "fine" end, print)
assert(ok and err == "fine")
ok, err = xpcall(function() error({}) end, function(e) return type(e) end)
assert(err == "table")
-- Errors inside the handler.
ok, err = xpcall(function() error("x") end, function() error("again") end)
assert(not ok)

-- Nested pcall and error rethrow.
ok, err = pcall(function()
    local ok2, err2 = pcall(error, "inner")
    assert(not ok2 and err2 == "inner")
    error("outer", 0)
end)
assert(err == "outer")

-- Errors in metamethods propagate.
local bad = setmetatable({}, {__index = function() error("index failed", 0) end})
ok, err = pcall(function() return bad.x end)
assert(err == "index failed")

-- Stack overflow is caught.
local function rec() return 1 + rec() end
ok, err = pcall(rec)
assert(not ok and err:find("stack overflow"), err)

-- assert with messages and values.
ok, err = pcall(assert, false, "custom")
assert(err == "custom")
ok, err = pcall(assert, nil)
assert(err:find("assertion failed!"))
assert(select("#", assert(1, 2, 3)) == 3)

-- error with non-string values keeps them.
ok, err = pcall(error, 42)
assert(err == 42)
ok, err = pcall(error, "lvl", 1)
assert(err == "lvl")

-- tostring of errors with line info from load.
local f = loadstring("local x = nil; return x.y", "=chunk")
ok, err = pcall(f)
assert(err == "chunk:1: attempt to index local 'x' (a nil value)", err)
f, err = loadstring("x = = 1", "=bad")
assert(f == nil and err:find("^bad:1:"), err)
f, err = loadstring("for", "=eof")
assert(f == nil and err:find("<eof>"), err)
f, err = loadstring("x = 'unterminated", "=str")
assert(f == nil and err:find("unfinished string"), err)
print("errors ok")
