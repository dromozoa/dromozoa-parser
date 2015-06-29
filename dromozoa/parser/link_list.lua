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

-- p, t, n

local function insert(prev, value)
  local next = prev[2]
  local this = { value, next, prev }
  prev[2] = this
  next[3] = this
end

local function remove(this)
  local next = this[2]
  local prev = this[3]
  prev[2] = next
  next[3] = prev
end

local function construct()
  local head = {}
  local tail = {}

  head[2] = tail
  tail[3] = head

  local this = {}

  function this:push_front(value)
    insert(head, value)
  end

  function this:push_back(value)
    insert(tail[3], value)
  end

  function this:pop_front()
    local node = head[2]
    local v = node[1]
    remove(node)
    return v
  end

  function this:pop_back()
    local node = tail[3]
    local v = node[1]
    remove(node)
    return v
  end

  function this:each()
    return coroutine.wrap(function ()
      local this = head[2]
      while this ~= tail do
        coroutine.yield(this[1])
        this = this[2]
      end
    end)
  end

  return this
end

return construct
