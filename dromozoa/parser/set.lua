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

function class:adapt()
  return setmetatable(self, metatable)
end

function class:insert(k, v)
  if v == nil then
    v = true
  end
  local u = self[k]
  if u == nil then
    self[k] = v
  end
  return u
end

function class:remove(k)
  local u = self[k]
  self[k] = nil
  return u
end

function class.includes(a, b)
  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end
  return true
end

function class.set_intersection(a, b)
  local m = 0
  for k in pairs(a) do
    if b[k] == nil then
      m = m + 1
      a[k] = nil
    end
  end
  return m
end

function class.set_union(a, b)
  local n = 0
  for k, v in pairs(b) do
    if a[k] == nil then
      n = n + 1
      a[k] = v
    end
  end
  return n
end

function class.set_difference(a, b)
  local m = 0
  for k in pairs(a) do
    if b[k] ~= nil then
      m = m + 1
      a[k] = nil
    end
  end
  return m
end

function class.set_symmetric_difference(a, b)
  local m = 0
  local n = 0
  for k, v in pairs(b) do
    if a[k] == nil then
      n = n + 1
      a[k] = v
    else
      m = m + 1
      a[k] = nil
    end
  end
  return m, n
end

return class
