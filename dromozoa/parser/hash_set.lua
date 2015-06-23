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

local function construct(_u, _v)
  local self = {}

  function self:clone()
    return construct(clone(_u), clone(_v))
  end

  function self:find(key)
    local h = hash(key)
    local u = _u[h]
    if u == nil then
      return false
    elseif equal(u, key) then
      return true
    end
    local v = _v[h]
    if v == nil then
      return false
    end
    for i = 1, #v do
      if equal(v[i], key) then
        return true
      end
    end
    return false
  end

  function self:each()
    return coroutine.wrap(function ()
      for _, u in pairs(_u) do
        coroutine.yield(u)
      end
      for _, v in pairs(_v) do
        for i = 1, #v do
          coroutine.yield(v[i])
        end
      end
    end)
  end

  function self:insert(key)
    local h = hash(key)
    local u = _u[h]
    if u == nil then
      _u[h] = key
      return true
    elseif equal(u, key) then
      return false
    end
    local v = _v[h]
    if v == nil then
      _v[h] = { key }
      return true
    end
    for i = 1, #v do
      if equal(v[i], key) then
        return false
      end
    end
    v[#v + 1] = key
    return true
  end

  function self:remove(key)
    local h = hash(key)
    local u = _u[h]
    if u == nil then
      return false
    elseif equal(u, key) then
      local v = _v[h]
      if v == nil then
        _u[h] = nil
      else
        _u[h] = table.remove(v, 1)
        if #v == 0 then
          _v[h] = nil
        end
      end
      return true
    end
    local v = _v[h]
    if v == nil then
      return false
    end
    for i = 1, #v do
      if equal(v[i], key) then
        table.remove(v, i)
        if #v == 0 then
          _v[h] = nil
        end
        return true
      end
    end
    return false
  end

  return self
end

return function ()
  return construct({}, {})
end
