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

local table_remove = table.remove

local function hash(value)
  return value % 2 + 1
end

local function construct()
  local _u = {}
  local _v = {}

  local self = {}

  function self:find(value)
    local h = hash(value)
    local u = _u[h]
    if u == nil then
      return false
    elseif equal(u, value) then
      return true
    end
    local v = _v[h]
    if v == nil then
      return false
    else
      for i = 1, #v do
        if equal(v[i], value) then
          return true
        end
      end
      return false
    end
  end

  function self:insert(value)
    local h = hash(value)
    local u = _u[h]
    if u == nil then
      _u[h] = value
      return true
    elseif equal(u, value) then
      return false
    end
    local v = _v[h]
    if v == nil then
      _v[h] = { value }
      return true
    else
      for i = 1, #v do
        if equal(v[i], value) then
          return false
        end
      end
      v[#v + 1] = value
      return true
    end
  end

  function self:remove(value)
    local h = hash(value)
    local u = _u[h]
    if u == nil then
      return false
    elseif equal(u, value) then
      local v = _v[h]
      if v == nil then
        _u[h] = nil
      else
        local n = #v
        _u[h] = v[n]
        if n == 1 then
          _v[h] = nil
        else
          v[n] = nil
        end
      end
      return true
    end
    local v = _v[h]
    if v == nil then
      return false
    else
      local n = #v
      if n == 1 then
        if equal(v[1], value) then
          _v[h] = nil
          return true
        end
      else
        for i = 1, n do
          if equal(v[i], value) then
            table_remove(v, i)
            return true
          end
        end
      end
    end
  end

  function self:get()
    return _u, _v
  end

  return self
end

return construct
