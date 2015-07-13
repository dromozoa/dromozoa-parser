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

local equal = require "dromozoa.parser.equal"
local hash = require "dromozoa.parser.hash"

local function hash(key)
  return #key % 2 + 100
end

local class = {}
local metatable = {}

local function get(self, key)
  local h = hash(key)
  local K = self[1]
  local k = K[h]
  if k == nil then
    return nil
  end
  if equal(k, key) then
    local V = self[2]
    local v = V[h]
    return v
  end
  local KS = self[3]
  local ks = KS[h]
  if ks == nil then
    return nil
  end
  for i = 1, #ks do
    if equal(ks[i], key) then
      local VS = self[4]
      local vs = VS[h]
      local v = vs[i]
      return v
    end
  end
  return nil
end

local function insert(self, key, value, overwrite)
  local h = hash(key)
  local K = self[1]
  local k = K[h]
  if k == nil then
    local V = self[2]
    K[h] = key
    V[h] = value
    return nil
  end
  if equal(k, key) then
    local V = self[2]
    local v = V[h]
    if overwrite then
      V[h] = value
    end
    return v
  end
  local KS = self[3]
  local ks = KS[h]
  if ks == nil then
    local VS = self[4]
    KS[h] = { key }
    VS[h] = { value }
    return nil
  end
  local n = #ks
  for i = 1, n do
    if equal(ks[i], key) then
      local VS = self[4]
      local vs = VS[h]
      local v = vs[i]
      if overwrite then
        vs[i] = value
      end
      return v
    end
  end
  local VS = self[4]
  local vs = VS[h]
  n = n + 1
  ks[n] = key
  vs[n] = value
  return nil
end

local function remove(self, key)
  local h = hash(key)
  local K = self[1]
  local k = K[h]
  if k == nil then
    return nil
  end
  local KS = self[3]
  local ks = KS[h]
  if equal(k, key) then
    local V = self[2]
    local v = V[h]
    if ks == nil then
      K[h] = nil
      V[h] = nil
    else
      local VS = self[4]
      local vs = VS[h]
      K[h] = table.remove(ks, 1)
      V[h] = table.remove(vs, 1)
      if #ks == 0 then
        KS[h] = nil
        VS[h] = nil
      end
    end
    return v
  end
  for i = 1, #ks do
    if equal(ks[i], key) then
      table.remove(ks, i)
      local VS = self[4]
      local vs = VS[h]
      local v = table.remove(vs, i)
      if #ks == 0 then
        KS[h] = nil
        VS[h] = nil
      end
      return v
    end
  end
  return nil
end

function class.new()
  return { {}, {}, {}, {} }
end

function class:adapt()
  return setmetatable(self, metatable)
end

function class:get(key)
  return get(self, key)
end

function class:put(key, value)
  if value == nil then
    return remove(self, key)
  else
    return insert(self, key, value, true)
  end
end

function class:insert(key, value)
  if value == nil then
    value = true
  end
  return insert(self, key, value, false)
end

function class:remove(key)
  return remove(self, key)
end

function metatable:__index(key)
  local fn = class[key]
  if fn == nil then
    return class.get(self, key)
  else
    return fn
  end
end

function metatable:__newindex(key, value)
  return class.put(self, key, value)
end

return class
