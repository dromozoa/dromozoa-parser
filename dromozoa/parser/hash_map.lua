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

local clone = require "dromozoa.commons.clone"
local equal = require "dromozoa.parser.equal"
local hash = require "dromozoa.parser.hash"

local metatable = {}

function metatable:__index(key)
  return self:find(key)
end

function metatable:__newindex(key, value)
  if value == nil then
    self:remove(key)
  else
    self:insert(key, value, true)
  end
end

local function construct(_u, _v, _w)
  local self = {}

  function self:clone()
    return construct(clone(_u), clone(_v), clone(_w))
  end

  function self:find(key)
    local h = hash(key)
    local u = _u[h]
    if u == nil then
      return nil
    elseif equal(u, key) then
      return _v[h]
    end
    local w = _w[h]
    if w == nil then
      return nil
    end
    for i = 1, #w, 2 do
      if equal(w[i], key) then
        return w[i + 1]
      end
    end
    return nil
  end

  function self:each()
    return coroutine.wrap(function ()
      for h, u in pairs(_u) do
        coroutine.yield(u, _v[h])
      end
      for _, w in pairs(_w) do
        for i = 1, #w, 2 do
          coroutine.yield(w[i], w[i + 1])
        end
      end
    end)
  end

  function self:insert(key, value, overwrite)
    local h = hash(key)
    local u = _u[h]
    if u == nil then
      _u[h] = key
      _v[h] = value
      return true
    elseif equal(u, key) then
      if overwrite then
        _v[h] = value
      end
      return false
    end
    local w = _w[h]
    if w == nil then
      _w[h] = { key, value }
      return true
    end
    local n = #w
    for i = 1, n, 2 do
      if equal(w[i], key) then
        if overwrite then
          w[i + 1] = value
        end
        return false
      end
    end
    w[n + 1] = key
    w[n + 2] = value
    return true
  end

  function self:remove(key)
    local h = hash(key)
    local u = _u[h]
    if u == nil then
      return false
    elseif equal(u, key) then
      local w = _w[h]
      if w == nil then
        _u[h] = nil
        _v[h] = nil
      else
        local u = table.remove(w, 1)
        local v = table.remove(w, 1)
        if #w == 0 then
          _w[h] = nil
        end
        _u[h] = u
        _v[h] = v
      end
      return true
    end
    local w = _w[h]
    if w == nil then
      return false
    end
    for i = 1, #w, 2 do
      if equal(w[i], key) then
        table.remove(w, i)
        table.remove(w, i)
        if #w == 0 then
          _w[h] = nil
        end
        return true
      end
    end
    return false
  end

  return setmetatable(self, metatable)
end

return function ()
  return construct({}, {}, {})
end
