-- Copyright (C) 2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local dump = require "dromozoa.parser.dump"

local data = {}
for i = 1, 256 do
  data[i] = { i, i * i }
end

local out = assert(io.open("test_dump.lua", "w"))

local source = {
  a = { {1}, {1,2}, {1,2,3}, {1,2}, {1} };
  b = { {1,2,3}, {1,2}, {1} };
  c = {1,2,3};
  d = data;
}
local root = dump(out, source)
out:write("return ", root, "\n")
out:close()

local result = assert(loadfile "test_dump.lua")()
for i = 1, 256 do
  assert(result.d[i][1] == i)
  assert(result.d[i][2] == i * i)
end
assert(result.a[1] == result.a[5])
assert(result.a[2] == result.a[4])
assert(result.a[3] == result.b[1])
assert(result.a[4] == result.b[2])
assert(result.a[5] == result.b[3])
assert(result.b[1] == result.c)
