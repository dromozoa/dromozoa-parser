-- Copyright (C) 2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local graph = require "dromozoa.graph"

return function (this)
  local max_state = this.max_state
  local epsilons = this.epsilons
  local transitions = this.transitions

  local that = graph()

  for u = 1, max_state do
    that:add_vertex()
  end

  if epsilons then
    for u, v in pairs(epsilons[1]) do
      that:add_edge(u, v)
    end
    for u, v in pairs(epsilons[2]) do
      that:add_edge(u, v)
    end
  end

  for u = 1, max_state do
    local map = {}
    -- TODO use <n>
    for byte = 0, 255 do
      local v = transitions[byte][u]
      if v then
        local item = map[v]
        if item then
          item.n = item.n + 1
          item[byte] = true
        else
          map[v] = { n = 1, [byte] = true }
        end
      end
    end
    for v, item in pairs(map) do
      that:add_edge(u, v)
    end
  end

  return that
end
