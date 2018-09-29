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
  local n = this.max_state
  local epsilons = this.epsilons
  local epsilons1
  local epsilons2
  if epsilons then
    epsilons1 = epsilons[1]
    epsilons2 = epsilons[2]
  else
    epsilons1 = {}
    epsilons2 = {}
    epsilons = { epsilons1, epsilons2 }
    this.epsilons = epsilons
  end
  local transitions = this.transitions

  local that_epsilons = that.epsilons
  if that_epsilons then
    for uid, vid in pairs(that_epsilons[1]) do
      epsilons1[n + uid] = n + vid
    end
    for uid, vid in pairs(that_epsilons[2]) do
      epsilons2[n + uid] = n + vid
    end
  end

  local that_transitions = that.transitions
  for byte = 0, 255 do
    local transition = transitions[byte]
    for uid, vid in pairs(that_transitions[byte]) do
      transition[n + uid] = n + vid
    end
  end

  local accept_states = {}
  for uid, accept in pairs(that.accept_states) do
    accept_states[n + uid] = accept
  end

  local max_state = n + that.max_state
  this.max_state = max_state
  that.max_state = max_state
  that.epsilons = epsilons
  that.transitions = transitions
  that.start_state = n + that.start_state
  that.accept_states = accept_states
  return this, that
end
