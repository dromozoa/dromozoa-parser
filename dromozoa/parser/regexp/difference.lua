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

return function (this, that)
  local this_max_state = this.max_state
  local that_max_state = that.max_state
  local this_transitions = this.transitions
  local that_transitions = that.transitions
  local that_accept_states = that.accept_states

  local n = this_max_state + 1

  local transitions = {}
  for byte = 0, 255 do
    transitions[byte] = {}
  end
  local accept_states = {}

  for i = 0, this_max_state do
    for j = 0, that_max_state do
      local u = i + n * j
      if u ~= 0 then
        for byte = 0, 255 do
          local x = this_transitions[byte][i]
          local y = that_transitions[byte][j]
          if not x then
            x = 0
          end
          if not y then
            y = 0
          end
          local v = x + n * y
          if v ~= 0 then
            transitions[byte][u] = v
          end
        end
      end
    end
  end

  for i, accept in pairs(this.accept_states) do
    accept_states[i] = accept
    for j = 1, that_max_state do
      if not that_accept_states[j] then
        local u = i + n * j
        accept_states[u] = accept
      end
    end
  end

  return {
    max_state = this_max_state + n * that_max_state;
    transitions = transitions;
    start_state = this.start_state + n * that.start_state;
    accept_states = accept_states;
  }
end
