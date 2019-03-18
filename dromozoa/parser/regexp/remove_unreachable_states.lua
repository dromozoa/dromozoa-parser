-- Copyright (C) 2019 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local function build_reachable_states(transitions, reachable_states, u)
  reachable_states[u] = true
  for byte = 0, 255 do
    local v = transitions[byte][u]
    if v and u ~= v and not reachable_states[v] then
      build_reachable_states(transitions, reachable_states, v)
    end
  end
end

return function (this)
  local max_state = this.max_state
  local transitions = this.transitions
  local start_state = this.start_state
  local accept_states = this.accept_states

  local reachable_states = {}
  build_reachable_states(transitions, reachable_states, start_state)

  local new_max_state = 0
  local map = {}
  for u = 1, max_state do
    if reachable_states[u] then
      new_max_state = new_max_state + 1
      map[u] = new_max_state
    end
  end

  local new_transitions = {}
  for byte = 0, 255 do
    new_transitions[byte] = {}
  end
  local new_accept_states = {}
  for u = 1, max_state do
    local U = map[u]
    if U then
      for byte = 0, 255 do
        local v = transitions[byte][u]
        if v then
          local V = map[v]
          if V then
            new_transitions[byte][U] = V
          end
        end
      end
      new_accept_states[U] = accept_states[u]
    end
  end

  return {
    max_state = new_max_state;
    transitions = new_transitions;
    start_state = map[start_state];
    accept_states = new_accept_states;
  }
end
