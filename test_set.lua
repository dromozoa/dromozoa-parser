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

local set = require "dromozoa.parser.set"
local json = require "dromozoa.json"
local clone = require "dromozoa.commons.clone"
local linked_hash_table = require "dromozoa.parser.linked_hash_table"

local a = linked_hash_table():adapt()
a.a = 1
a.b = 1
a.c = 1

local b = linked_hash_table():adapt()
b.b = 2
b.c = 2
b.d = 2
b.e = 2
b.f = 2
b.g = 2
b.h = 2

local function next_index(index, this, key)
  if index ~= nil then
    if type(index) == "function" then
      return index(this, key)
    else
      return index[key]
    end
  end
end

local function adapt(this)
  local metatable = getmetatable(this)
  if metatable == nil then
    metatable = {}
  end
  local h = metatable.__index
  metatable.__index = function (this, key)
    local v = set[key]
    if v ~= nil then
      return v
    end
    return next_index(h, this, key)
  end
  return setmetatable(this, metatable)
end

local a = adapt(a)
print(set.set_symmetric_difference(a, b))
for k, v in pairs(a) do
  print(k, v)
end
print(a.a)
print(a.set_difference)
-- print(json.encode(a))

-- print(op.set_symmetric_difference(a, b))

local x = set.adapt({ a = true, b = true, c = true })

print(x:set_intersection({ a = true, c = true }))
print(x.a, x.b, x.c)


