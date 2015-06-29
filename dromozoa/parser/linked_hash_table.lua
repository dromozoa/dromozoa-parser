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

local adapt_hash_table = require "dromozoa.parser.adapt_hash_table"
local hash_table = require "dromozoa.parser.hash_table"
local linked_list = require "dromozoa.parser.linked_list"

local function construct(_t, _u, _v)
  local self = {}

  function self:clone()
    return construct(_t:clone(), _u:clone(), _v:clone())
  end

  function self:length()
    return _t:length()
  end

  function self:find(key)
    local id = _t:find(key)
    if id == nil then
      return nil
    end
    return _v:get(id)
  end

  function self:each()
    return coroutine.wrap(function ()
      for id, v in _v:each() do
        coroutine.yield(_u:get(id), v)
      end
    end)
  end

  function self:insert(key, value, overwrite)
    local id = _t:find(key)
    if id == nil then
      _u:push_back(key)
      _t:insert(key, _v:push_back(value))
      return nil
    end
    local v = _v:get(id)
    if overwrite then
      _v:set(id, value)
    end
    return v
  end

  function self:remove(key)
    local id = _t:remove(key)
    if id == nil then
      return nil
    end
    _u:remove(id)
    return _v:remove(id)
  end

  function self:adapt()
    return adapt_hash_table(self)
  end

  return self
end

return function ()
  return construct(hash_table(), linked_list(), linked_list())
end
