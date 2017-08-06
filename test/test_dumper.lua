-- Copyright (C) 2017 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local equal = require "dromozoa.commons.equal"
local dumper = require "dromozoa.parser.dumper"

local data = {}
for i = 1, 256 do
  data[#data + 1] = { i, i ^ 2 }
end

local out = assert(io.open("test_dumper.lua", "w"))

local source = {
  a = { {1},{1,2},{1,2,3},{1,2},{1} };
  b = { {1,2,3},{1,2},{1} };
  c = {1,2,3};
  d = data;
}
local root = dumper(out, source)
out:write("return ", root, "\n")
out:close()

local result = assert(loadfile("test_dumper.lua"))()
assert(equal(source, result))
