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

local hash_set = require "dromozoa.parser.hash_set"
local index_set = require "dromozoa.parser.index_set"

local function count(map)
  local n = 0
  print("--")
  for k, v in map:each() do
    n = n + 1
    print(k, v)
  end
  return n
end

local function test(set)
  assert(not set:insert(1))
  assert(not set:insert(2))
  assert(not set:insert(3))
  assert(not set:insert(4))
  assert(not set:insert(5))
  assert(not set:insert(6))
  assert(not set:insert(7))
  assert(not set:insert(8))
  assert(count(set) == 8)

  assert(set:find(8))
  assert(not set:find(9))

  assert(set:insert(1))
  assert(set:insert(2))
  assert(set:insert(3))
  assert(set:insert(4))
  assert(set:insert(5))
  assert(set:insert(6))
  assert(set:insert(7))
  assert(set:insert(8))
  assert(count(set) == 8)

  local set2 = set:clone()

  assert(set:remove(1))
  assert(set:remove(2))
  assert(count(set) == 6)

  assert(set:remove(5))
  assert(set:remove(6))
  assert(not set:remove(9))
  assert(count(set) == 4)

  assert(set:remove(7))
  assert(set:remove(8))
  assert(count(set) == 2)

  assert(count(set2) == 8)

  assert(not set:find(1))
  assert(set2:find(1))

  assert(set2[1])
  assert(set2[2])
  assert(not set2[42])
  set2[1] = nil
  set2[2] = nil
  set2[42] = true
  assert(not set2[1])
  assert(not set2[2])
  assert(set2[42])
  assert(count(set2) == 7)
end

test(hash_set())
test(index_set())
