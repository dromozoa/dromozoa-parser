-- Copyright (C) 2017,2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local concat = require "dromozoa.parser.builder.concat"

local class = { is_pattern = true }

function class:clone()
  local that = self[3]
  if that then
    return class(self[1], self[2]:clone(), that:clone())
  else
    return class(self[1], self[2]:clone())
  end
end

function class:concatenation(that)
  local construct = class.construct
  local self = construct(self)
  local that = construct(that)
  return class(2, self, that) -- concatenation
end

function class:union(that)
  local construct = class.construct
  local self = construct(self)
  local that = construct(that)
  return class(3, self, that) -- union
end

function class:repetition(that)
  if that == 0 or that == "*" then
    return class(4, self) -- 0 or more repetition
  elseif that == 1 or that == "+" then
    return self * self:clone()^0
  elseif that == -1 or that == "?" then
    return class(5, self) -- optional
  end
  if type(that) == "number" then
    if that < 0 then
      local items = { self^-1 }
      for i = 2, -that do
        items[i] = self:clone()^-1
      end
      return concat(items)
    else
      local items = { self }
      for i = 2, that do
        items[i] = self:clone()
      end
      items[that + 1] = self:clone()^0
      return concat(items)
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
      return concat(items)
    else
      local items = { self }
      for i = 2, m do
        items[i] = self:clone()
      end
      for i = m + 1, n do
        items[i] = self:clone()^-1
      end
      return concat(items)
    end
  end
end

function class:difference(that)
  local construct = class.construct
  local self = construct(self)
  local that = construct(that)
  return class(6, self, that) -- difference
end

local metatable = {
  __index = class;
  __pow = class.repetition;
  __mul = class.concatenation;
  __add = class.union;
  __sub = class.difference;
}

return setmetatable(class, {
  __call = function (_, ...)
    return setmetatable({...}, metatable)
  end;
})
