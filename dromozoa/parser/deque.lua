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

local function construct(_t, _u, _v)
  local self = {}

  function self:clone()
    return construct(clone(_t), _u, _v)
  end

  function self:front(i)
    if i then
      return _t[_u + i - 1]
    else
      return _t[_u]
    end
  end

  function self:back(i)
    if i then
      return _t[_v - i + 1]
    else
      return _t[_v]
    end
  end

  function self:empty()
    return _v < _u
  end

  function self:size()
    return _v - _u + 1
  end

  function self:each()
    return coroutine.wrap(function ()
      for id = _u, _v do
        coroutine.yield(id, _t[id])
      end
    end)
  end

  function self:push_front(value)
    local id = _u - 1
    _t[id] = value
    _u = id
    return id
  end

  function self:push_back(value)
    local id = _v + 1
    _t[id] = value
    _v = id
    return id
  end

  function self:pop_front()
    local id = _u
    local value = _t[id]
    _t[id] = nil
    _u = id + 1
    return value
  end

  function self:pop_back()
    local id = _v
    local value = _t[id]
    _t[id] = nil
    _v = id - 1
    return value
  end

  return self
end

return function ()
  return construct({}, 1, 0)
end
