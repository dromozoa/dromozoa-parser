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

function class.new(...)
  return {...}
end

function class.P(that)
  if type(that) == "string" then
    local this = class("concat")
    for i = 1, #that do
      this[i + 1] = class("[", { [that:byte(i)] = true })
    end
    return this
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
    return class("+", self)
  elseif that == -1 or that == "?" then
    return class("?", self)
  end
  if type(that) == "number" then
    if that < 0 then
      return class("{m,n}", self, 0, -that)
    else
      return class("{m,}", self, that)
    end
  else
    local m = that[1]
    local n = that[2]
    if n == nil then
      return class("{m}", self, m)
    else
      return class("{m,n}", self, m, n)
    end
  end
end

function class.metatable:__unm()
  assert(self[1] == "[")
  local set = self[2]
  for i = 0, 255 do
    if set[i] then
      set[i] = nil
    else
      set[i] = true
    end
  end
  return self
end

return setmetatable(class, {
  __call = function (_, ...)
    return setmetatable(class.new(...), class.metatable)
  end;
})
