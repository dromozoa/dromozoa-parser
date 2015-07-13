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

local function HANDLE_K() end
local function HANDLE_V() end
local function HANDLE_KS() end
local function HANDLE_VS() end

local class = {}
local metatable = {}

local function insert(self, key, value, overwrite)
  if key == nil then
    error "table index is nil"
  end
  local h = hash(key)
  local K = self[HANDLE_K]
  local k = K[h]
  if k == nil then
    local V = self[HANDLE_V]
    K[h] = key
    V[h] = value
    return nil
  end
  if equal(k, key) then
    local V = self[HANDLE_V]
    local v = V[h]
    if overwrite then
      V[h] = value
    end
    return v
  end
  local KS = self[HANDLE_KS]
  local ks = KS[h]
  if ks == nil then
    local VS = self[HANDLE_VS]
    KS[h] = { key }
    VS[h] = { value }
    return nil
  end
  local n = #ks
  for i = 1, n do
    if equal(ks[i], key) then
      local VS = self[HANDLE_VS]
      local vs = VS[h]
      local v = vs[i]
      if overwrite then
        vs[i] = value
      end
      return v
    end
  end
  local VS = self[HANDLE_VS]
  local vs = VS[h]
  n = n + 1
  ks[n] = key
  vs[n] = value
  return nil
end

function class.new()
  return {
    [HANDLE_K] = {};
    [HANDLE_V] = {};
    [HANDLE_KS] = {};
    [HANDLE_VS] = {};
  }
end

function class:adapt()
  return setmetatable(self, metatable)
end

function class:get(key)
  if key == nil then
    return nil
  end
  local h = hash(key)
  local K = self[HANDLE_K]
  local k = K[h]
  if k == nil then
    return nil
  end
  if equal(k, key) then
    local V = self[HANDLE_V]
    local v = V[h]
    return v
  end
  local KS = self[HANDLE_KS]
  local ks = KS[h]
  if ks == nil then
    return nil
  end
  for i = 1, #ks do
    if equal(ks[i], key) then
      local VS = self[HANDLE_VS]
      local vs = VS[h]
      local v = vs[i]
      return v
    end
  end
  return nil
end

function class:each()
  return coroutine.wrap(function ()
    local K = self[HANDLE_K]
    local V = self[HANDLE_V]
    for h, k in pairs(K) do
      coroutine.yield(k, V[h])
    end
    local KS = self[HANDLE_KS]
    local VS = self[HANDLE_VS]
    for h, ks in pairs(KS) do
      local vs = VS[h]
      for i = 1, #ks do
        coroutine.yield(ks[i], vs[i])
      end
    end
  end)
end

function class:put(key, value)
  if value == nil then
    return class.remove(self, key)
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
  if key == nil then
    error "table index is nil"
  end
  local h = hash(key)
  local K = self[HANDLE_K]
  local k = K[h]
  if k == nil then
    return nil
  end
  local KS = self[HANDLE_KS]
  local ks = KS[h]
  if equal(k, key) then
    local V = self[HANDLE_V]
    local v = V[h]
    if ks == nil then
      K[h] = nil
      V[h] = nil
    else
      local VS = self[HANDLE_VS]
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
      local VS = self[HANDLE_VS]
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

function metatable:__index(key)
  local fn = class[key]
  if fn == nil then
    return class.get(self, key)
  else
    return fn
  end
end

metatable.__newindex = class.put
metatable.__pairs = class.each

return setmetatable(class, {
  __call = function ()
    return class.adapt(class.new())
  end;
})
