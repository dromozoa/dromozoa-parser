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

local error_message = require "dromozoa.parser.error_message"

local source = [[
123456789
123456789
123456789
]]

local function test(position, i, j)
  local result = error_message("test", source, position)
  local expect = ("<unknown>:%d:%d: test"):format(i, j)
  assert(result == expect)
end

local function test_eof(position)
  local result = error_message("test", source, position)
  local expect = ("<unknown>:eof: test"):format(i, j)
  assert(result == expect)
end

print(error_message("test", source,  5))
print(error_message("test", source, 15))
print(error_message("test", source, 25))
print(error_message("test", source, 35))

test( 1, 1,  1)
test( 5, 1,  5)
test(10, 1, 10)
test(11, 2,  1)
test(15, 2,  5)
test(20, 2, 10)
test(21, 3,  1)
test(25, 3,  5)
test(30, 3, 10)

test_eof(31)
test_eof(32)
