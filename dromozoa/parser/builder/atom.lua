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

local pattern = require "dromozoa.parser.builder.pattern"

local any = {}
for byte = 0, 255 do
  any[byte] = true
end

local super = pattern
local class = {}
local metatable = {
  __index = class;
  __mul = super.metatable.__mul;
  __pow = super.metatable.__pow;
}
class.metatable = metatable

function class.any()
  return class(any)
end

function class.char(that)
  return class({ [that:byte()] = true })
end

function class.range(that)
  local set = {}
  for i = 1, #that, 2 do
    local a, b = that:byte(i, i + 1)
    for j = a, b do
      set[j] = true
    end
  end
  return class(set)
end

function class.set(that)
  local set = {}
  for i = 1, #that do
    set[that:byte(i)] = true
  end
  return class(set)
end

function class:clone()
  return class(self[2])
end

function metatable:__add(that)
  local pattern = class.super.pattern
  local self = pattern(self)
  local that = pattern(that)
  if getmetatable(that) == metatable then
    local set = {}
    for byte in pairs(self[2]) do
      set[byte] = true
    end
    for byte in pairs(that[2]) do
      set[byte] = true
    end
    return class(set)
  else
    return super.metatable.__add(self, that)
  end
end

function metatable:__sub(that)
  local pattern = class.super.pattern
  local self = pattern(self)
  local that = pattern(that)
  if getmetatable(that) == metatable then
    local set = {}
    for byte in pairs(self[2]) do
      set[byte] = true
    end
    for byte in pairs(that[2]) do
      set[byte] = nil
    end
    return class(set)
  else
    return super.metatable.__add(self, that)
  end
end

function metatable:__unm()
  local set = self[2]
  local neg = {}
  for byte = 0, 255 do
    if not set[byte] then
      neg[byte] = true
    end
  end
  return class(neg)
end

return setmetatable(class, {
  __index = super;
  __call = function (_, set)
    return setmetatable({ 1, set }, metatable)
  end;
})
