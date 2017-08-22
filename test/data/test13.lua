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

local u = "foo"

local function f(a, b, c)
  do
    local a = a .. a
    print(a, b, c .. c, u .. u, 1.0)
  end
  x = 105
  return 0x69, a, 1.
end
f("foo", true, [[
abc
def
ghi
]])

for i = 1, 10 do
  local i = i + 1
  print(i)
end

for a, b in pairs({}) do
  print(a, b)
end

