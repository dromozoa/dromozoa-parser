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

local tag_names = {
  "[";
  "concat";
  "|";
  "*";
  "?";
}

local tag_table = {}
for i = 1, #tag_names do
  tag_table[tag_names[i]] = i
end

local function concat(items, i)
  if i == 1 then
    return items[i]
  else
    return concat(items, i - 1) * items[i]
  end
end

local class = {}

function class.new(tag_name, ...)
  return { tag_table[tag_name], ... }
end

function class.concat(items)
  return concat(items, #items)
end

function class:as(name)
  self.name = name
  return self
end

class.metatable = {
  __index = class;
}

function class.metatable:__add(that)
  local pattern = class.super.pattern
  local self = pattern(self)
  local that = pattern(that)
  return class("|", self, that)
end

function class.metatable:__mul(that)
  local pattern = class.super.pattern
  local self = pattern(self)
  local that = pattern(that)
  return class("concat", self, that)
end

function class.metatable:__pow(that)
  if that == 0 or that == "*" then
    return class("*", self)
  elseif that == 1 or that == "+" then
    return self * class("*", self)
  elseif that == -1 or that == "?" then
    return class("?", self)
  end
  if type(that) == "number" then
    if that < 0 then
      local items = {}
      for i = 1, -that do
        items[i] = self^-1
      end
      return class.concat(items)
    else
      local items = {}
      for i = 1, that do
        items[i] = self
      end
      items[that + 1] = self^0
      return class.concat(items)
    end
  else
    local m = that[1]
    local n = that[2]
    if n == nil then
      n = m
    end
    local items = {}
    for i = 1, m do
      items[i] = self
    end
    for i = m + 1, n do
      items[i] = self^-1
    end
    return class.concat(items, n)
  end
end

function class.metatable:__call(that)
  self.action = that
  return self
end

return setmetatable(class, {
  __call = function (_, tag_name, ...)
    return setmetatable(class.new(tag_name, ...), class.metatable)
  end;
})
