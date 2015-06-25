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

local hash_map = require "dromozoa.parser.hash_map"
local index_map = require "dromozoa.parser.index_map"

local function count(map)
  local n = 0
  print("--")
  for k, v in map:each() do
    n = n + 1
    print(k, v)
  end
  return n
end

local function test(map)
  assert(map:insert(1, "1") == nil)
  assert(map:insert(2, "2") == nil)
  assert(map:insert(3, "3") == nil)
  assert(map:insert(4, "4") == nil)
  assert(map:insert(5, "5") == nil)
  assert(map:insert(6, "6") == nil)
  assert(count(map) == 6)

  local map2 = map:clone()

  assert(map:insert(5, "!") == "5")
  assert(map:insert(6, "!") == "6")
  assert(map:insert(7, "7") == nil)
  assert(map:insert(8, "8") == nil)
  assert(count(map) == 8)

  assert(map:find(1) == "1")
  assert(map:find(2) == "2")
  assert(map:find(3) == "3")
  assert(map:find(4) == "4")
  assert(map:find(5) == "5")
  assert(map:find(6) == "6")
  assert(map:find(7) == "7")
  assert(map:find(8) == "8")

  assert(map:remove(1) == "1")
  assert(map:remove(2) == "2")
  assert(count(map) == 6)

  assert(map:remove(7) == "7")
  assert(map:remove(8) == "8")
  assert(count(map) == 4)

  assert(map:remove(3) == "3")
  assert(map:remove(4) == "4")
  assert(count(map) == 2)

  assert(map:remove(5) == "5")
  assert(map:remove(6) == "6")
  assert(count(map) == 0)

  assert(count(map2) == 6)

  assert(map2:find(6) == "6")
  assert(map2:insert(6, "!", true) == "6")
  assert(map2:find(6) == "!")
  assert(map2:insert(5, "!", true) == "5")
  assert(map2:insert({1,2,3,4}, true) == nil)

  assert(map2:find(5)== "!")
  assert(map2:find(6)== "!")
  assert(map2:find({1,2,3,4}))
end

test(hash_map())
test(index_map())
