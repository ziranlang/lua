-- The string library, patterns and string.format.
assert(string.len("abc") == 3 and ("abc"):len() == 3)
assert(("hello"):sub(2, 3) == "el" and ("hello"):sub(-3) == "llo" and ("hello"):sub(2) == "ello")
assert(("hello"):sub(0) == "hello" and ("hello"):sub(10) == "" and ("hello"):sub(-100, 2) == "he")
assert(("Hello"):upper() == "HELLO" and ("Hello"):lower() == "hello")
assert(("ab"):rep(3) == "ababab" and ("ab"):rep(0) == "" and ("ab"):rep(3, ",") == "ab,ab,ab")
assert(("abc"):reverse() == "cba" and ("A"):byte() == 65)
local b1, b2, b3 = ("abc"):byte(1, -1)
assert(b1 == 97 and b2 == 98 and b3 == 99 and string.char(72, 105) == "Hi")
assert(select("#", ("abc"):byte(10)) == 0)

-- find with plain text and patterns.
assert(("hello world"):find("wor") == 7)
local s, e = ("hello world"):find("o w")
assert(s == 5 and e == 7)
assert(("a.b"):find(".", 1, true) == 2 and ("a.b"):find("%.") == 2)
assert(("abc"):find("b", -1) == nil and ("abc"):find("") == 1 and ("abc"):find("", 10) == nil)
assert(("hello"):find("l+") == 3)
local fs, fe, cap = ("key=value"):find("(%w+)=")
assert(fs == 1 and fe == 4 and cap == "key")

-- match: classes, anchors, captures, position captures.
assert(("  trim  "):match("^%s*(.-)%s*$") == "trim")
assert(("2024-01-15"):match("(%d+)-(%d+)-(%d+)") == "2024")
local y, m, d = ("2024-01-15"):match("(%d+)-(%d+)-(%d+)")
assert(y == "2024" and m == "01" and d == "15")
assert(("abc123"):match("%a+") == "abc" and ("abc123"):match("%d+$") == "123")
assert(("hello"):match("()ll()") == 3)
local p1, p2 = ("hello"):match("()ll()")
assert(p1 == 3 and p2 == 5)
assert(("[tag]"):match("%[(.-)%]") == "tag" and ("x"):match("y") == nil)
assert(("THE (quick) fox"):match("%((%a+)%)") == "quick")
assert(("f(a(b)c)d"):match("%b()") == "(a(b)c)")
assert(("THE quick"):match("%f[%a]%a+", 4) == "quick")
assert(("aaa"):match("a-b") == nil and ("aaab"):match("a-b") == "aaab" and ("aaa"):match("^a*$") == "aaa")
assert(("x = 1"):match("^(%w+)%s*=%s*(%w+)$") == "x")
assert(("abab"):match("(ab)%1") == "ab")
assert(("hello.lua"):match("^(.+)%.(%w+)$") == "hello")
assert(("a,b,,c"):match("[^,]*", 5) == "" and ("A_1"):match("[%w_]+") == "A_1")
assert(("-12.5e3"):match("^[+-]?%d+%.?%d*[eE]?[+-]?%d*$") == "-12.5e3")
assert(("ab]c"):match("[]]") == "]" and ("a-b"):match("[a%-]+") == "a-" and ("^x"):match("[%^x]+") == "^x")
assert(("\0a"):match("%z") == "\0" and ("Tab\t"):match("%c") == "\t" and ("a!b"):match("%p") == "!")
assert(("abc"):match(".-$") == "abc" and ("abc"):match("^(a?)(b)") == "a")

-- gmatch.
local words = {}
for w in ("one two  three"):gmatch("%a+") do words[#words + 1] = w end
assert(#words == 3 and words[3] == "three")
local kv = {}
for k, v in ("a=1, b=2"):gmatch("(%w+)=(%w+)") do kv[k] = v end
assert(kv.a == "1" and kv.b == "2")
local n = 0
for _ in ("abc"):gmatch("") do n = n + 1 end
assert(n == 4)

-- gsub with string, table and function replacements.
assert(("hello world"):gsub("o", "0") == "hell0 w0rld")
local r, count = ("hello world"):gsub("o", "0")
assert(count == 2)
assert(("hello"):gsub("l", "L", 1) == "heLlo")
assert(("hello world"):gsub("(%w+)", "<%1>") == "<hello> <world>")
assert(("abc"):gsub("%w", "%0%0") == "aabbcc" and ("a%b"):gsub("%%", "%%%%") == "a%%b")
assert(("$name is $age"):gsub("%$(%w+)", {name = "Bob", age = 42}) == "Bob is 42")
assert(("$x"):gsub("%$(%w+)", {}) == "$x")
assert(("1 2 3"):gsub("%d", function(d) return d * 2 end) == "2 4 6")
assert(("abc"):gsub("b", function() return nil end) == "abc")
assert(("abc"):gsub("", "-") == "-a-b-c-")
assert(("  x  "):gsub("^%s+", "") == "x  ")
assert(("hello"):gsub("l+", function(m) return "[" .. m .. "]" end) == "he[ll]o")
assert(not pcall(string.find, "x", "(") and ("x"):gsub("(", "") == "x")
assert(not pcall(string.find, "x", "[a"))
assert(not pcall(string.rep))

-- string.format.
local F = string.format
assert(F("%d", 42) == "42" and F("%5d", 42) == "   42" and F("%-5d|", 42) == "42   |" and F("%05d", -42) == "-0042")
assert(F("%x %X %o", 255, 255, 8) == "ff FF 10" and F("%#x", 255) == "0xff" and F("%x", -1) == "ffffffffffffffff")
assert(F("%.2f", 3.14159) == "3.14" and F("%8.3f", 3.14159) == "   3.142" and F("%f", 1) == "1.000000")
assert(F("%e", 12345.678) == "1.234568e+04" and F("%.0e", 5) == "5e+00" and F("%E", 0.5) == "5.000000E-01")
assert(F("%g", 100000) == "100000" and F("%g", 1000000) == "1e+06" and F("%g", 0.0001) == "0.0001" and F("%g", 0.00001) == "1e-05")
assert(F("%.14g", 0.1) == "0.1" and F("%.3g", 3.14159) == "3.14" and F("%g", 2.5) == "2.5")
assert(F("%s and %s", "a", 1) == "a and 1" and F("%10s|", "hi") == "        hi|" and F("%-4s|", "hi") == "hi  |")
assert(F("%.2s", "hello") == "he" and F("%q", 'a "q"\n') == '"a \\"q\\"\\\n"')
assert(F("%c%c", 72, 105) == "Hi" and F("%%") == "%" and F("%5.1f%%", 99.5) == " 99.5%")
assert(F("%s", setmetatable({}, {__tostring = function() return "obj" end})) == "obj")
assert(F("%d", 3.7) == "3" and F("%+d", 5) == "+5" and F("% d", 5) == " 5" and F("%i", -0) == "0")
assert(F("%.3f", 2.0005) == "2.001" or F("%.3f", 2.0005) == "2.000")
assert(F("%.1f", 0.05) == "0.1" or F("%.1f", 0.05) == "0.0")
assert(F("%.0f", 0.5) == "0" and F("%.0f", 1.5) == "2" and F("%.0f", 2.5) == "2")
assert(F("%5.2s|", "abc") == "   ab|")
assert(F("%f", 1/0) == "inf" and F("%f", -1/0) == "-inf")
assert(F("%.20f", 0.1) == "0.10000000000000000555")
assert(F("%.17g", 0.1) == "0.10000000000000001")
assert(F("%a", 1) == "0x1p+0" and F("%a", -0.5) == "-0x1p-1" and F("%A", 255.5) == "0X1.FFP+7" and F("%.1a", 1.03125) == "0x1.0p+0")
assert(not pcall(F, "%d", "x") and not pcall(F, "%y", 1))

-- tostring / tonumber.
assert(tonumber("42") == 42 and tonumber("0x1F") == 31 and tonumber("  12  ") == 12 and tonumber("1e3") == 1000)
assert(tonumber("abc") == nil and tonumber("") == nil and tonumber("12a") == nil and tonumber(nil) == nil)
assert(tonumber("ff", 16) == 255 and tonumber("777", 8) == 511 and tonumber("zz", 36) == 1295 and tonumber("8", 8) == nil)
assert(tonumber(" -7 ") == -7 and tonumber("-0x10") == -16 and tonumber(".5") == 0.5 and tonumber("5.") == 5)
assert(tostring(nil) == "nil" and tostring(true) == "true" and tostring(12) == "12")
assert(tostring(print):find("^builtin: ") or tostring(print):find("^function: "))
assert(tostring({}):find("^table: "))
assert(#tostring(12345.678) == 9)

-- Strings with embedded zeros.
local z = "a\0b"
assert(#z == 3 and z:byte(2) == 0 and z:sub(3) == "b" and z .. "c" == "a\0bc")
assert(("x\0y"):find("\0", 1, true) == 2 and ("x\0y"):gsub("%z", "-") == "x-y")
-- LuaJIT 2.1 \u{XXX} escapes encode UTF-8.
assert("\u{41}\u{e9}\u{20AC}\u{1F600}" == "A\195\169\226\130\172\240\159\152\128")
assert(not loadstring("return \"\\u{110000}\"") and not loadstring("return \"\\u41\""))
print("strings ok")
