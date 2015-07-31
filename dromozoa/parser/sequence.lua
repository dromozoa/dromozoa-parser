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

local function push(self, n, value, ...)
  if value == nil then
    return self
  else
    n = n + 1
    self[n] = value
    return push(self, n, ...)
  end
end

local class = {}

function class.new(that, i, j)
  if that == nil then
    return {}
  else
    return class.copy({}, that, i, j)
  end
end

function class:top(i)
  return self[#self]
end

function class:push(...)
  return push(self, #self, ...)
end

function class:pop()
  local n = #self
  local v = self[n]
  self[n] = nil
  return v
end

function class:copy(that, i, j)
  if i == nil then
    i = 1
  elseif i < 0 then
    i = #that + 1 + i
  end
  if j == nil then
    j = #that
  elseif j < 0 then
    j = #that + 1 + j
  end
  local n = #self
  for i = i, j do
    n = n + 1
    self[n] = that[i]
  end
  return self
end

function class:each()
  return coroutine.wrap(function ()
    for _, v in ipairs(self) do
      coroutine.yield(v)
    end
  end)
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (class, that, i, j)
    return setmetatable(class.new(that, i, j), metatable)
  end;
})
