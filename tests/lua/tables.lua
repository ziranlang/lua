-- Table construction, length, iteration and the table library.
local t = {1, 2, 3, x = "a", ["y z"] = "b", [10] = "ten"}
assert(#t == 3 and t.x == "a" and t["y z"] == "b" and t[10] == "ten")
t[#t + 1] = 4
assert(#t == 4)
t[2.0] = "two"
assert(t[2] == "two")
local keys = 0
for k, v in pairs(t) do keys = keys + 1 end
assert(keys == 7)
local sum = 0
for i, v in ipairs({5, 6, 7, nil, 9}) do sum = sum + v end
assert(sum == 18)
-- Deleting during traversal is allowed.
local d = {}
for i = 1, 50 do d["k" .. i] = i end
for k in pairs(d) do d[k] = nil end
assert(next(d) == nil)
-- Big array and hash parts.
local big = {}
for i = 1, 10000 do big[i] = i * 2 end
assert(#big == 10000 and big[5000] == 10000)
local h = {}
for i = 1, 5000 do h["key" .. i] = i end
local count = 0
for k, v in pairs(h) do count = count + 1; assert(h[k] == v) end
assert(count == 5000)
-- Negative, float and boolean keys.
local m = {}
m[-1] = "neg"; m[0.5] = "half"; m[true] = "yes"; m[false] = "no"
assert(m[-1] == "neg" and m[0.5] == "half" and m[true] == "yes" and m[false] == "no")
assert(not pcall(function() m[nil] = 1 end))
assert(not pcall(function() m[0/0] = 1 end))
assert(m[nil] == nil)

-- table.insert / remove / concat.
local l = {}
table.insert(l, "a"); table.insert(l, "c"); table.insert(l, 2, "b")
assert(table.concat(l) == "abc" and table.concat(l, "-") == "a-b-c")
assert(table.concat(l, ",", 2) == "b,c" and table.concat(l, ",", 2, 2) == "b" and table.concat({}, "x") == "")
assert(table.remove(l) == "c" and #l == 2)
assert(table.remove(l, 1) == "a" and l[1] == "b" and #l == 1)
assert(table.remove({}) == nil)
assert(table.concat({1, 2.5, "x"}, " ") == "1 2.5 x")
assert(not pcall(table.concat, {1, {}, 3}))
assert(table.maxn({1, 2, [10] = 1}) == 10 and table.getn({1, 2}) == 2)

-- table.sort.
local s = {5, 2, 8, 1, 9, 3, 7, 4, 6, 10}
table.sort(s)
for i = 1, 10 do assert(s[i] == i) end
table.sort(s, function(a, b) return a > b end)
for i = 1, 10 do assert(s[i] == 11 - i) end
local words = {"pear", "apple", "fig", "banana"}
table.sort(words)
assert(table.concat(words, " ") == "apple banana fig pear")
local recs = {}
for i = 1, 200 do recs[i] = {v = (i * 7919) % 1000} end
table.sort(recs, function(a, b) return a.v < b.v end)
for i = 2, 200 do assert(recs[i - 1].v <= recs[i].v) end
assert(not pcall(table.sort, {1, "x", 2}))

-- unpack.
local a, b, c = unpack({1, 2, 3})
assert(a == 1 and b == 2 and c == 3)
assert(select("#", unpack({1, nil, 3}, 1, 3)) == 3)
assert(select("#", unpack({}, 1, 0)) == 0)

-- foreach / foreachi.
local acc = 0
table.foreachi({1, 2, 3}, function(i, v) acc = acc + v end)
assert(acc == 6)
assert(table.foreach({a = 1}, function(k, v) return k end) == "a")

-- Length border of arrays.
local holes = {}
holes[1] = 1; holes[2] = 2; holes[3] = 3
holes[3] = nil
assert(#holes == 2)

-- rawlen-like behavior: # ignores __index.
local proxy = setmetatable({}, {__index = {1, 2, 3}})
assert(#proxy == 0 and proxy[2] == 2)
print("tables ok")
