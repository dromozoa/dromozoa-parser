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
for char = 0, 255 do
  any[char] = true
end

local class = {}
local super = pattern

function class.new(tag_name, ...)
  return super(tag_name, ...)
end

function class.any()
  return class("[", any)
end

function class.char(that)
  return class("[", { [that:byte()] = true })
end

function class.range(that)
  local set = {}
  for i = 1, #that, 2 do
    local a, b = that:byte(i, i + 1)
    for j = a, b do
      set[j] = true
    end
  end
  return class("[", set)
end

function class.set(that)
  local set = {}
  for i = 1, #that do
    set[that:byte(i)] = true
  end
  return class("[", set)
end

class.metatable = {}

function class.metatable:__add(that)
  if that[1] == "[" then
    local set = {}
    for char in pairs(self[2]) do
      set[char] = true
    end
    for char in pairs(that[2]) do
      set[char] = true
    end
    return class("[", set)
  else
    return super.metatable.__add(self, that)
  end
end

function class.metatable:__unm()
  local set = self[2]
  local neg = {}
  for char = 0, 255 do
    if not set[char] then
      neg[char] = true
    end
  end
  return class("[", neg)
end

return setmetatable(class, {
  __index = super;
  __call = function (_, tag_name, ...)
    return setmetatable(class.new(tag_name, ...), class.metatable)
  end;
})
