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
