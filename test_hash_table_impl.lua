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

local json = require "dromozoa.json"
local hash_table_impl = require "dromozoa.parser.hash_table_impl"

local t = hash_table_impl.adapt(hash_table_impl.new())
assert(t:insert({}) == nil)
assert(t:insert({}) == true)
assert(t:remove({}) == true)
assert(t:remove({}) == nil)

local t = hash_table_impl.adapt(hash_table_impl.new())
t[{}] = 17
t[{1}] = 23
t[{1,2}] = 37
t[{1,2,3}] = 42
t[{1,2,3,4}] = 69
t[{1,2,3,4,5}] = 105
t[{1,2,3,4,5,6}] = 666

print(json.encode(t))
assert(t[{}] == 17)
assert(t[{1}] == 23)
assert(t[{1,2}] == 37)
assert(t[{1,2,3}] == 42)
assert(t[{1,2,3,4}] == 69)
assert(t[{1,2,3,4,5}] == 105)
assert(t[{1,2,3,4,5,6}] == 666)

t[{}] = nil
t[{1}] = nil

print(json.encode(t))
assert(t[{}] == nil)
assert(t[{1}] == nil)
assert(t[{1,2}] == 37)
assert(t[{1,2,3}] == 42)
assert(t[{1,2,3,4}] == 69)
assert(t[{1,2,3,4,5}] == 105)
assert(t[{1,2,3,4,5,6}] == 666)

t[{1,2,3,4,5}] = nil
t[{1,2,3,4,5,6}] = nil

print(json.encode(t))
assert(t[{}] == nil)
assert(t[{1}] == nil)
assert(t[{1,2}] == 37)
assert(t[{1,2,3}] == 42)
assert(t[{1,2,3,4}] == 69)
assert(t[{1,2,3,4,5}] == nil)
assert(t[{1,2,3,4,5,6}] == nil)

t[{1,2,3,4}] = nil

print(json.encode(t))
assert(t[{}] == nil)
assert(t[{1}] == nil)
assert(t[{1,2}] == 37)
assert(t[{1,2,3}] == 42)
assert(t[{1,2,3,4}] == nil)
assert(t[{1,2,3,4,5}] == nil)
assert(t[{1,2,3,4,5,6}] == nil)

t[{1,2}] = nil
t[{1,2,3}] = nil

print(json.encode(t))
assert(t[{}] == nil)
assert(t[{1}] == nil)
assert(t[{1,2}] == nil)
assert(t[{1,2,3}] == nil)
assert(t[{1,2,3,4}] == nil)
assert(t[{1,2,3,4,5}] == nil)
assert(t[{1,2,3,4,5,6}] == nil)

