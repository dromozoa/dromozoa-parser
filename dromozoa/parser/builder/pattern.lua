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

local class = {}
local metatable = {
  __index = class;
}
class.metatable = metatable

function class.concat(items)
  local result = items[1]
  for i = 2, #items do
    result = result * items[i]
  end
  return result
end

function class:clone()
  local that = self[3]
  if that == nil then
    return class(self[1], self[2]:clone())
  else
    return class(self[1], self[2]:clone(), that:clone())
  end
end

function metatable:__add(that)
  local pattern = class.super.pattern
  local self = pattern(self)
  local that = pattern(that)
  return class(3, self, that) -- union
end

function metatable:__sub(that)
  local pattern = class.super.pattern
  local self = pattern(self)
  local that = pattern(that)
  return class(6, self, that) -- difference
end

function metatable:__mul(that)
  local pattern = class.super.pattern
  local self = pattern(self)
  local that = pattern(that)
  return class(2, self, that) -- concatenation
end

function metatable:__pow(that)
  if that == 0 or that == "*" then
    return class(4, self) -- 0 or more repetition
  elseif that == 1 or that == "+" then
    return self * self:clone()^"*"
  elseif that == -1 or that == "?" then
    return class(5, self) -- optional
  end
  if type(that) == "number" then
    if that < 0 then
      local items = { self^-1 }
      for i = 2, -that do
        items[i] = self:clone()^-1
      end
      return class.concat(items)
    else
      local items = { self }
      for i = 2, that do
        items[i] = self:clone()
      end
      items[that + 1] = self:clone()^"*"
      return class.concat(items)
    end
  else
    local m = that[1]
    local n = that[2]
    if n == nil then
      n = m
    end
    if m == 0 then
      local items = { self^-1 }
      for i = 2, n do
        items[i] = self:clone()^-1
      end
      return class.concat(items)
    else
      local items = { self }
      for i = 2, m do
        items[i] = self:clone()
      end
      for i = m + 1, n do
        items[i] = self:clone()^-1
      end
      return class.concat(items)
    end
  end
end

function metatable:__call(that)
  self.action = that
  return self
end

return setmetatable(class, {
  __call = function (_, ...)
    return setmetatable({...}, metatable)
  end;
})
