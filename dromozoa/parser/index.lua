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
local map = require "dromozoa.parser.map"

local function construct(_data, _index)
  local self = {}

  function self:clone()
    return construct(_data:clone(), clone(_index))
  end

  function self:find(key)
    return _data:find(key)
  end

  function self:each()
    return coroutine.wrap(function ()
      for i = 1, #_index do
        local key = _index[i]
        coroutine.yield(key, _data:find(key))
      end
    end)
  end

  function self:insert(key, ...)
    local result = _data:insert(key, ...)
    if result == nil then
      _index[#_index + 1] = key
    end
    return result
  end

  function self:remove(key)
    local result = _data:remove(key)
    if result ~= nil then
      for i = 1, #_index do
        if _index[i] == key then
          table.remove(_index, i)
          return result
        end
      end
    end
    return result
  end

  return map(self)
end

return function (data)
  return construct(data, {})
end
