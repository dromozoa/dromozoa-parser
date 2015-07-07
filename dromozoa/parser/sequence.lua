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

local class = {}
local metatable = { __index = class }

function class:copy(i, j)
  if i == nil then
    i = 1
  end
  if j == nil then
    j = #self
  elseif j < 0 then
    j = #self + j + 1
  end
  local k = 1 - i
  local that = {}
  for i = i, j do
    that[k + i] = self[i]
  end
  return that
end

function class:adapt()
  return setmetatable(self, metatable)
end

function class:copy_adapt(i, j)
  return class.adapt(class.copy(self, i, j))
end

function class:front()
  return self[1]
end

function class:back()
  return self[#self]
end

function class:push_front(v)
  table.insert(self, 1, v)
  return self
end

function class:push_back(v)
  self[#self + 1] = v
  return self
end

function class.concat(a, b, i, j)
  if i == nil then
    i = 1
  end
  if j == nil then
    j = #b
  elseif j < 0 then
    j = #b + 1 + j
  end
  local k = #a + 1 - i
  for i = i, j do
    a[k + i] = b[i]
  end
  return a
end

return class
