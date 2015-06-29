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

  local _prev = { [tail] = head }
  local _next = { [head] = tail }
  local _value = {}
  local _n = 0

  local this = {}

  function this:insert(prev, value)
    local next = _next[prev]
    local id = _n + 1
    _prev[id] = prev
    _next[id] = next
    _value[id] = value
    _n = id
    _prev[next] = id
    _next[prev] = id
    return id
  end

  function this:remove(id)
    local prev = _prev[id]
    local next = _next[id]
    local value = _value[id]
    _prev[id] = nil
    _next[id] = nil
    _value[id] = nil
    _next[prev] = next
    _prev[next] = prev
    return value
  end

  function this:push_front(value)
    return this:insert(head, value)
  end

  function this:push_back(value)
    return this:insert(_prev[tail], value)
  end

  function this:pop_front()
    return this:remove(_next[head])
  end

  function this:pop_back()
    return this:remove(_prev[tail])
  end

  function this:each()
    return coroutine.wrap(function ()
      local i = _next[head]
      while i ~= tail do
        coroutine.yield(_value[i])
        i = _next[i]
      end
    end)
  end

  return this
end

return function ()
  return construct({}, {}, {}, 0)
end
