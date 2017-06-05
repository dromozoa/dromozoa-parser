-- Copyright (C) 2017 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local function compile(regexp)
  local transitions = regexp.transitions
  local accept_states = regexp.accept_states

  local new_transitions = {}
  for char = 0, 256 do
    local b = char - 255
    local transition = transitions[char]
    for u, v in pairs(transition) do
      new_transitions[u * 256 + b] = v
    end
  end

  local max_accept_state
  for u in pairs(accept_states) do
    if not max_accept_state or max_accept_state < u then
      max_accept_state = u
    end
  end

  return {
    max_state = this.max_state;
    max_accept_state = this.max_accept_state;
    transitions = new_transitions;
    start_state = this.start_state;
    accept_states = this.accept_states;
  }
end

local class = {}

function class.new(this)
  return compile(this)
end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, regexp)
    return setmetatable(class.new(regexp), class.metatable)
  end;
})
