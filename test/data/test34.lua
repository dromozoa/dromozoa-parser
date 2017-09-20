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

local f1 = function (x, ...)
  print(x, ...)
  return ...
end

local function f2(...)
  print(f2, ...)
end

function f3_1(...)
  print(...)
end

local f3_2

function f3_2(...)
  print(...)
end

local a = { b = {} }

function a.f3(...)
  print(...)
end

function a:f4(...)
  print(self, ...)
end

function a.b.f3(...)
  print(...)
end

function a.b:f4(...)
  print(self, ...)
end

f1(f1(f1(1, 2, 3)))
f2(4, 5, 6)
