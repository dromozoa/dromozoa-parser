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

local function construct(_t, _u, _v, _n)
  local self = {}

  function self:clone()
    return construct(clone(_t), clone(_u), clone(_v), _n)
  end

  function self:get(id)
    return _v[id]
  end

  function self:put(id, value)
    local v = _v[id]
    _v[id] = value
    return v
  end

  function self:each()
    return coroutine.wrap(function ()
      local id = _u[0]
      while id ~= 0 do
        coroutine.yield(id, _v[id])
        id = _u[id]
      end
    end)
  end

  function self:insert(t, value)
    local u = _u[t]
    local id = _n + 1
    _t[id] = t
    _u[id] = u
    _v[id] = value
    _n = id
    _t[u] = id
    _u[t] = id
    return id
  end

  function self:remove(id)
    local t = _t[id]
    local u = _u[id]
    local v = _v[id]
    _t[id] = nil
    _u[id] = nil
    _v[id] = nil
    _u[t] = u
    _t[u] = t
    return v
  end

  function self:push_front(value)
    return self:insert(0, value)
  end

  function self:push_back(value)
    return self:insert(_t[0], value)
  end

  function self:pop_front()
    return self:remove(_u[0])
  end

  function self:pop_back()
    return self:remove(_t[0])
  end

  return self
end

return function ()
  return construct({ [0] = 0 }, { [0] = 0 }, {}, 0)
end
