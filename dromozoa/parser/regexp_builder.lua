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

local clone = require "dromozoa.commons.clone"
local regexp = require "dromozoa.parser.regexp"

local any = {}
for i = 0, 255 do
  any[i] = true
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
  return { regexp.tag_table[tag_name], ... }
end

function class.P(that)
  local t = type(that)
  if t == "number" then
    local items = {}
    for i = 1, that do
      items[i] = class("[", any)
    end
    return concat(items, that)
  elseif t == "string" then
    local items = {}
    local n = #that
    for i = 1, n do
      items[i] = class("[", { [that:byte(i)] = true })
    end
    return concat(items, n)
  else
    return that
  end
end

function class.R(that)
  local set = {}
  for i = 1, #that, 2 do
    local a, b = that:byte(i, i + 1)
    for j = a, b do
      set[j] = true
    end
  end
  return class("[", set)
end

function class.S(that)
  local set = {}
  for i = 1, #that do
    set[that:byte(i)] = true
  end
  return class("[", set)
end

class.metatable = {
  __index = class;
}

local P = class.P

function class.metatable:__add(that)
  return class("|", P(self), P(that))
end

function class.metatable:__mul(that)
  return class("concat", P(self), P(that))
end

function class.metatable:__pow(that)
  if that == 0 or that == "*" then
    return class("*", self)
  elseif that == 1 or that == "+" then
    return self * class("*", clone(self))
  elseif that == -1 or that == "?" then
    return class("?", self)
  end
  if type(that) == "number" then
    if that < 0 then
      local n = -that
      local items = { class("?", self) }
      for i = 2, n do
        items[i] = class("?", clone(self))
      end
      return concat(items, n)
    else
      local n = that + 1
      local items = { self }
      for i = 2, that do
        items[i] = clone(self)
      end
      items[n] = class("*", clone(self))
      return concat(items, n)
    end
  else
    local m = that[1]
    local n = that[2]
    if n == nil or m == n then
      assert(m > 0)
      local items = { self }
      for i = 2, m do
        items[i] = clone(self)
      end
      return concat(items, m)
    else
      assert(m < n)
      if m == 0 then
        return self ^ -n
      else
        assert(m > 0)
        local items = { self }
        for i = 2, m do
          items[i] = clone(self)
        end
        for i = m + 1, n do
          items[i] = class("?", clone(self))
        end
        return concat(items, n)
      end
    end
  end
end

function class.metatable:__unm()
  assert(self[1] == regexp.tag_table["["])
  local set1 = self[2]
  local set2 = {}
  for i = 0, 255 do
    if not set1[i] then
      set2[i] = true
    end
  end
  self[2] = set2
  return self
end

return setmetatable(class, {
  __call = function (_, ...)
    return setmetatable(class.new(...), class.metatable)
  end;
})
