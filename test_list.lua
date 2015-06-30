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

local deque = require "dromozoa.parser.deque"
local equal = require "dromozoa.parser.equal"
local linked_list = require "dromozoa.parser.linked_list"

local function to_array(list)
  local array = {}
  for _, v in list:each() do
    array[#array + 1] = v
  end
  return array
end

local function test(list)
  assert(list:empty())

  local id = list:push_back(4)
  list:push_back(5)
  list:push_back(6)
  list:push_front(1)
  list:push_front(2)
  list:push_front(3)
  assert(not list:empty())
  assert(equal(to_array(list), { 3, 2, 1, 4, 5, 6 }))

  local list2 = list:clone()

  assert(list:pop_front() == 3)
  assert(list:pop_back() == 6)
  assert(equal(to_array(list), { 2, 1, 4, 5 }))
  assert(list:front() == 2)
  assert(list:back() == 5)

  assert(equal(to_array(list2), { 3, 2, 1, 4, 5, 6 }))

  return id
end

local list = deque()
test(list)
assert(list:front(1) == 2)
assert(list:front(2) == 1)
assert(list:back(1) == 5)
assert(list:back(2) == 4)

local list = linked_list()
local id = test(list)

assert(list:get(id) == 4)
assert(list:put(id, 17) == 4)
assert(list:get(id) == 17)
assert(equal(to_array(list), { 2, 1, 17, 5 }))

list:insert(id, 23)
assert(equal(to_array(list), { 2, 1, 17, 23, 5 }))
assert(list:remove(id) == 17)
assert(equal(to_array(list), { 2, 1, 23, 5 }))
