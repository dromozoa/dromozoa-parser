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
local hash_map = require "dromozoa.parser.hash_map"
local index_set = require "dromozoa.parser.index_set"
local index_map = require "dromozoa.parser.index_map"

local function includes(a, b)
  for k in b:each() do
    if a:find(k) == nil then
      return false
    end
  end
  return true
end

local function set_intersection(a, b, c)
  for k, v in a:each() do
    if b:find(k) ~= nil then
      c:insert(k, v)
    end
  end
  return c
end

local function set_union(a, b, c)
  for k, v in a:each() do
    c:insert(k, v)
  end
  for k, v in b:each() do
    c:insert(k, v)
  end
  return c
end

local function set_difference(a, b, c)
  for k, v in a:each() do
    if b:find(k) == nil then
      c:insert(k, v)
    end
  end
  return c
end

local function set_symmetric_difference(a, b, c)
  for k, v in a:each() do
    if b:find(k) == nil then
      c:insert(k, v)
    end
  end
  for k, v in b:each() do
    if a:find(k) == nil then
      c:insert(k, v)
    end
  end
  return c
end

local a = index_set()
a:insert("a")
a:insert("b")
a:insert("c")

local b = index_set()
b:insert("b")
b:insert("c")
b:insert("d")

local function dump(set)
  for k in set:each() do
    io.write(k, " ")
  end
  io.write("\n")
end

dump(a)
dump(b)
print(includes(a, b))
dump(set_intersection(a, b, index_set()))
dump(set_union(a, b, index_set()))
dump(set_difference(a, b, index_set()))
dump(set_symmetric_difference(a, b, index_set()))

