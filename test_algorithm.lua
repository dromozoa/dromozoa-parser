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

local linked_hash_table = require "dromozoa.parser.linked_hash_table"

local function includes(a, b)
  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end
  return true
end

local function set_intersection(a, b, c)
  for k, v in pairs(a) do
    if b[k] ~= nil then
      c[k] = v
    end
  end
  return c
end

local function set_union(a, b, c)
  for k, v in pairs(a) do
    c[k] = v
  end
  for k, v in pairs(b) do
    if a[k] == nil then
      c[k] = v
    end
  end
  return c
end

local function set_difference(a, b, c)
  for k, v in pairs(a) do
    if b[k] == nil then
      c[k] = v
    end
  end
  return c
end

local function set_symmetric_difference(a, b, c)
  for k, v in pairs(a) do
    if b[k] == nil then
      c[k] = v
    end
  end
  for k, v in pairs(b) do
    if a[k] == nil then
      c[k] = v
    end
  end
  return c
end

local a = linked_hash_table():adapt()
a.a = 1
a.b = 1
a.c = 1

local b = linked_hash_table():adapt()
b.b = 2
b.c = 2
b.d = 2

local function dump(set)
  print("--")
  for k, v in pairs(set) do
    print(k, v)
  end
  return set
end

dump(a)
dump(b)
print(includes(a, b))
print(includes(a, a))
dump(set_intersection(a, b, linked_hash_table():adapt()))
local c = dump(set_union(a, b, linked_hash_table():adapt()))
assert(c.b == 1)
dump(set_difference(a, b, linked_hash_table():adapt()))
dump(set_symmetric_difference(a, b, linked_hash_table():adapt()))
