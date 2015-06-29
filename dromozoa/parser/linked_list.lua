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

local function construct()
  local head = 0
  local tail = 0

  local _t = { [tail] = head }
  local _u = { [head] = tail }
  local _v = {}
  local _n = 0

  local this = {}

  function this:insert(t, v)
    local u = _u[t]
    local n = _n + 1
    _t[n] = t
    _u[n] = u
    _v[n] = v
    _n = n
    _t[u] = n
    _u[t] = n
    return n
  end

  function this:remove(n)
    local t = _t[n]
    local u = _u[n]
    local v = _v[n]
    _t[n] = nil
    _u[n] = nil
    _v[n] = nil
    _u[t] = u
    _t[u] = t
    return v
  end

  function this:push_front(value)
    return this:insert(head, value)
  end

  function this:push_back(value)
    return this:insert(_t[tail], value)
  end

  function this:pop_front()
    return this:remove(_u[head])
  end

  function this:pop_back()
    return this:remove(_t[tail])
  end

  function this:each()
    return coroutine.wrap(function ()
      local i = _u[head]
      while i ~= tail do
        coroutine.yield(_v[i])
        i = _u[i]
      end
    end)
  end

  return this
end

return function ()
  return construct({}, {}, {}, 0)
end
