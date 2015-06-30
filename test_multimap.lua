-- Copyright (C) 2015 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local equal = require "dromozoa.parser.equal"
local linked_hash_table = require "dromozoa.parser.linked_hash_table"
local multimap = require "dromozoa.parser.multimap"

local map = {}

multimap.insert(map, "foo", 1)
multimap.insert(map, "foo", 2)
multimap.insert(map, "foo", 3)
multimap.insert(map, "bar", 4)

assert(equal(map.foo, { 1, 2, 3 }))
assert(equal(map.bar, { 4 }))

local sum = {
  foo = 0;
  bar = 0;
}
for k, v in multimap.each(map) do
  sum[k] = sum[k] + v
end
assert(sum.foo == 6)
assert(sum.bar == 4)

local map = linked_hash_table():adapt()

multimap.insert(map, "foo", 1)
multimap.insert(map, "foo", 2)
multimap.insert(map, "foo", 3)
multimap.insert(map, "bar", 4)
multimap.insert(map, "baz", 5)
multimap.insert(map, "qux", 6)
multimap.insert(map, "qux", 7)
multimap.insert(map, 1, "foo")
multimap.insert(map, 2, "bar")
multimap.insert(map, 3, "baz")
multimap.insert(map, 4, "qux")

local expect = {
  { "foo", 1 };
  { "foo", 2 };
  { "foo", 3 };
  { "bar", 4 };
  { "baz", 5 };
  { "qux", 6 };
  { "qux", 7 };
  { 1, "foo" };
  { 2, "bar" };
  { 3, "baz" };
  { 4, "qux" };
}

local i = 0
for k, v in multimap.each(map) do
  i = i + 1
  assert(k == expect[i][1])
  assert(v == expect[i][2])
end
