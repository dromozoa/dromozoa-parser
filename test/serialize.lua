-- Copyright (C) 2019 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local n = 3.14
local i = 42

local source = {
  1.7976931348623157e+308; -- DBL_MAX
  4.9406564584124654e-324; -- DBL_DENORM_MIN
  2.2250738585072014e-308; -- DBL_MIN
  2.2204460492503131e-16; -- DBL_EPSILON
  0x7FFFFFFFFFFFFFFF;
  0xFFFFFFFFFFFFFFFF;
  -1;
  42;
}

local handle = assert(io.open("test.txt", "wb"))
for i = 1, #source do
  local v = source[i]
  if math.type and math.type(v) == "integer" then
    handle:write(("%d\n"):format(v))
  else
    handle:write(("%.17g\n"):format(v))
  end
end
handle:close()

local handle = assert(io.open "test.txt", "rb")
local result = {}
for i = 1, #source do
  result[i] = handle:read "*n"
  assert(source[i] == result[i], "error " .. i)
end
handle:close()

local handle = assert(io.open("test.txt", "wb"))
handle:write [[
42:666.
]]
handle:close()

local handle = assert(io.open "test.txt", "rb")
assert(handle:read "*n" == 42)
assert(handle:read(1) == ":")
assert(handle:read "*n" == 666)
assert(handle:read(1) == "\n")
assert(handle:read(1) == nil)

os.remove "test.txt"

-- https://cr.yp.to/proto/netstrings.txt




