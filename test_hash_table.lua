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
local hash_table = require "dromozoa.parser.hash_table"
local linked_hash_table = require "dromozoa.parser.linked_hash_table"

local function count(t)
  local n = 0
  for k, v in t:each() do
    n = n + 1
  end
  return n
end

local function test(t)
  assert(t:insert(1, "1") == nil)
  assert(t:insert(2, "2") == nil)
  assert(t:insert(3, "3") == nil)
  assert(t:insert(4, "4") == nil)
  assert(t:insert(5, "5") == nil)
  assert(t:insert(6, "6") == nil)
  assert(count(t) == 6)

  local t2 = t:clone()

  assert(t:insert(5, "!") == "5")
  assert(t:insert(6, "!") == "6")
  assert(t:insert(7, "7") == nil)
  assert(t:insert(8, "8") == nil)
  assert(count(t) == 8)

  assert(t:find(1) == "1")
  assert(t:find(2) == "2")
  assert(t:find(3) == "3")
  assert(t:find(4) == "4")
  assert(t:find(5) == "5")
  assert(t:find(6) == "6")
  assert(t:find(7) == "7")
  assert(t:find(8) == "8")

  assert(t:remove(1) == "1")
  assert(t:remove(2) == "2")
  assert(count(t) == 6)

  assert(t:remove(7) == "7")
  assert(t:remove(8) == "8")
  assert(count(t) == 4)

  assert(t:remove(3) == "3")
  assert(t:remove(4) == "4")
  assert(count(t) == 2)

  assert(t:remove(5) == "5")
  assert(t:remove(6) == "6")
  assert(count(t) == 0)

  assert(t2:find(5) == "5")
  assert(t2:insert(5, "!", true) == "5")
  assert(t2:find(5) == "!")
  assert(t2:find(6) == "6")
  assert(t2:insert(6, "!", true) == "6")
  assert(t2:find(6) == "!")
  assert(count(t2) == 6)

  assert(t2:insert({1,2,3,4}, "1234") == nil)
  assert(t2:find({1,2,3,4}) == "1234")
  assert(t2:insert({1,2,3,4}, "!!!!") == "1234")
  assert(t2:find({1,2,3,4}) == "1234")
  assert(t2:insert({1,2,3,4}, "!!!!", true) == "1234")
  assert(t2:find({1,2,3,4}) == "!!!!")
  assert(count(t2) == 7)

  local a = t:adapt()

  a[1] = "foo"
  a[2] = "bar"
  a[3] = "baz"
  a["foo"] = 1
  a["bar"] = 2
  a["baz"] = 3
  a[{1}] = 1
  a[{1,2}] = 12
  a[{1,2,3}] = 123
  a[{1,2,3,4}] = 1234
  a[{1,2,3,4}] = "!!!!"
  a[{1,2,3}] = "!!!"
  a[{1,2}] = "!!"
  a[{1}] = "!"

  assert(count(t) == 10)
  assert(a[1] == "foo")
  assert(a["foo"] == 1)
  assert(a[{1}] == "!")
end

test(hash_table())
test(linked_hash_table())

local t = linked_hash_table()
local a = t:adapt()
a.foo = 1
a.bar = 2
a.baz = 3
a.qux = 4
a[1] = "foo"
a[2] = "bar"
a[3] = "baz"
a[4] = "qux"

local expect = {
  { "foo", 1 };
  { "bar", 2 };
  { "baz", 3 };
  { "qux", 4 };
  { 1, "foo" };
  { 2, "bar" };
  { 3, "baz" };
  { 4, "qux" };
}

local i = 0
for k, v in pairs(a) do
  i = i + 1
  assert(k == expect[i][1])
  assert(v == expect[i][2])
end
