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
local adapt_hash_table = require "dromozoa.parser.adapt_hash_table"

local function construct(_t, _u, _v, _w)
  local self = {}

  function self:clone()
    return construct(clone(_t), clone(_u), clone(_v), clone(_w))
  end

  function self:length()
    return #_t
  end

  function self:find(key)
    if type(key) == "table" then
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
    else
      return _t[key]
    end
  end

  function self:each()
    return coroutine.wrap(function ()
      for k, v in pairs(_t) do
        coroutine.yield(k, v)
      end
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
    if type(key) == "table" then
      local h = hash(key)
      local u = _u[h]
      if u == nil then
        _u[h] = key
        _v[h] = value
        return nil
      elseif equal(u, key) then
        local v = _v[h]
        if overwrite then
          _v[h] = value
        end
        return v
      end
      local w = _w[h]
      if w == nil then
        _w[h] = { key, value }
        return nil
      end
      local n = #w
      for i = 1, n, 2 do
        if equal(w[i], key) then
          local j = i + 1
          local v = w[j]
          if overwrite then
            w[j] = value
          end
          return v
        end
      end
      w[n + 1] = key
      w[n + 2] = value
      return nil
    else
      local v = _t[key]
      if v == nil or overwrite then
        _t[key] = value
      end
      return v
    end
  end

  function self:remove(key)
    if type(key) == "table" then
      local h = hash(key)
      local u = _u[h]
      if u == nil then
        return nil
      elseif equal(u, key) then
        local v = _v[h]
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
        return v
      end
      local w = _w[h]
      if w == nil then
        return nil
      end
      for i = 1, #w, 2 do
        if equal(w[i], key) then
          table.remove(w, i)
          local v = table.remove(w, i)
          if #w == 0 then
            _w[h] = nil
          end
          return v
        end
      end
      return nil
    else
      local v = _t[key]
      _t[key] = nil
      return v
    end
  end

  function self:adapt()
    return adapt_hash_table(self)
  end

  return self
end

return function ()
  return construct({}, {}, {}, {})
end
