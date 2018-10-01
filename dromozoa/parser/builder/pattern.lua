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

local any = {}
for byte = 0, 255 do
  any[byte] = true
end

local function concat(items)
  local result = items[1]
  for i = 2, #items do
    result = result * items[i]
  end
  return result
end

local class = { is_pattern = true }
local metatable = { __index = class }

function class:clone()
  if self[1] == 1 then
    return setmetatable({ 1, self[2] }, metatable) -- character class
  else
    local that = self[3]
    if that then
      return setmetatable({ self[1], self[2]:clone(), that:clone() }, metatable)
    else
      return setmetatable({ self[1], self[2]:clone() }, metatable)
    end
  end
end

function class.any()
  return setmetatable({ 1, any }, metatable) -- character class
end

function class.char(that)
  return setmetatable({ 1, { [that:byte()] = true } }, metatable) -- character class
end

function class.range(that)
  local set = {}
  for i = 1, #that, 2 do
    local a, b = that:byte(i, i + 1)
    for j = a, b do
      set[j] = true
    end
  end
  return setmetatable({ 1, set }, metatable) -- character class
end

function class.set(that)
  local set = {}
  for i = 1, #that do
    set[that:byte(i)] = true
  end
  return setmetatable({ 1, set }, metatable) -- character class
end

function metatable:__mul(that)
  local self = class(self)
  local that = class(that)
  return setmetatable({ 2, self, that }, metatable) -- concatenation
end

function metatable:__add(that)
  local self = class(self)
  local that = class(that)
  if self[1] == 1 and that[1] == 1 then
    local set = {}
    for byte in pairs(self[2]) do
      set[byte] = true
    end
    for byte in pairs(that[2]) do
      set[byte] = true
    end
    return setmetatable({ 1, set }, metatable) -- character class
  else
    return setmetatable({ 3, self, that }, metatable) -- union
  end
end

function metatable:__pow(that)
  if that == 0 or that == "*" then
    return setmetatable({ 4, self }, metatable) -- 0 or more repetition
  elseif that == 1 or that == "+" then
    return self * self:clone()^0
  elseif that == -1 or that == "?" then
    return setmetatable({ 5, self }, metatable) -- optional
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

function metatable:__sub(that)
  local self = class(self)
  local that = class(that)
  if self[1] == 1 and that[1] == 1 then
    local set = {}
    for byte in pairs(self[2]) do
      set[byte] = true
    end
    for byte in pairs(that[2]) do
      set[byte] = nil
    end
    return setmetatable({ 1, set }, metatable) -- character class
  else
    return setmetatable({ 6, self, that }, metatable) -- difference
  end
end

function metatable:__unm()
  -- TODO impl non-character level negation
  assert(self[1] == 1)
  local set = self[2]
  local neg = {}
  for byte = 0, 255 do
    if not set[byte] then
      neg[byte] = true
    end
  end
  return setmetatable({ 1, neg }, metatable) -- character class
end

return setmetatable(class, {
  __call = function (_, that)
    local t = type(that)
    if t == "number" then
      if that == 1 then
        return class.any()
      else
        local items = {}
        for i = 1, that do
          items[i] = class.any()
        end
        return concat(items)
      end
    elseif t == "string" then
      if #that == 1 then
        return class.char(that)
      else
        local items = {}
        for i = 1, #that do
          items[i] = class.char(that:sub(i, i))
        end
        return concat(items)
      end
    else
      return that
    end
  end;
})
