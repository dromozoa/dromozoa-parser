-- Copyright (C) 2017 Tomoyuki Fujimori <moyu@dromozoa.com>
--
-- This file is part of dromozoa-parser.
--
-- dromozoa-parser is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- dromozoa-parser is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with dromozoa-parser.  If not, see <http://www.gnu.org/licenses/>.

local dumper = require "dromozoa.commons.dumper"
local equal = require "dromozoa.commons.equal"
local regexp = require "dromozoa.parser.regexp"
local regexp_builder = require "dromozoa.parser.regexp_builder"

local function dfs_discover_node(node, fn, depth)
  if depth == nil then
    depth = 1
  else
    depth = depth + 1
  end
  fn(node, depth - 1)
  if node[1] > regexp.max_terminal_tag then
    for i = 2, #node do
      dfs_discover_node(node[i], fn, depth)
    end
  end
end

local check_table = {}

local function dump(p)
  dfs_discover_node(p, function (node, depth)
    local id = tostring(node)
    assert(not check_table[id])
    check_table[id] = true

    local tag_name = regexp.tag_names[node[1]]
    io.write(("  "):rep(depth), tag_name)
    if tag_name == "[" then
      local set = node[2]
      for i = 20, 126 do
        if set[i] then
          io.write(string.char(i))
        end
      end
      io.write("]")
    end
    io.write("\n")
  end)
  return p
end

local P = regexp_builder.P
local R = regexp_builder.R
local S = regexp_builder.S

-- [A-Z]|[13579]abcdef|(xyz)*
local p1 = R "AZaz09" + S "13579" * "abcdef" + P "xyz" ^0
-- [^a-z]^{1,2}
local p2 = (-R"AZ") ^{1,2}
-- (abc)?def
local p3 = P "abc" ^-1 * "def"
-- (abc){3}
local p4 = P "abc" ^{3} * P "def" ^-2
-- a?a?a?
local p5 = P "a" ^-3
-- abcd
local p6 = P "abcd"

local p = p5
-- print(dumper.encode(p, { pretty = true }))
-- dump(p)

print("----")
local a = dump(P"abc" * P"abc"^"*")
print("--")
local b = dump(P"abc"^"+")
print("--")
local c = dump((P "a" * "b" * "c")^"+")
assert(equal(a, b))
assert(equal(a, c))

print("----")
local a = dump(P"a"^-3)
print("--")
local b = dump(P"a"^{0,3})
print("--")
local c = dump(P"a"^"?" * P"a"^"?" * P"a"^"?")
assert(equal(a, b))
assert(equal(a, c))

print("----")
local a = dump(P"a"^4)
print("--")
local b = dump(P"a" * "a" * "a" * "a" * P"a"^"*")
assert(equal(a, b))

print("----")
local a = dump(P"a"^{4})
print("----")
local b = dump(P"a"^{4,4})
print("--")
local c = dump(P"a" * "a" * "a" * "a")
assert(equal(a, b))
assert(equal(a, c))

print("----")
local a = dump(P"a"^{3,6})
print("--")
local b = dump(P"a" * "a" * "a" * P"a"^"?" * P"a"^"?" * P"a"^"?")
assert(equal(a, b))

print("----")
local a = dump(P(1)^{4})
print("--")
local b = dump(P(4))
assert(equal(a, b))
