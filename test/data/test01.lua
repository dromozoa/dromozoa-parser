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

local function f(a, b, c, ...)
  local x = { a = { b = { c = a } } }
  print(a, b and 1 or 2, c .. c, x.a.b.c)
  return 42
end
f("foo", true, [[
abc
def
ghi
]])

--12345678901234567890123456789
data = { 1, 2, 3, 4, "日本語" }
repeat
  local n = #data
  print(data[n])
  data[n] = nil
until n == 1

do
  local a, b = 1, 2
  local b = 3
  print(a, b)
end

local i = 10
for i = 1, i do
  print(i)
end

--[[ end ]]
