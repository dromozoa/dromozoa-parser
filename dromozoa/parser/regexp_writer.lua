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

local unpack = require "dromozoa.commons.unpack"

local class = {}

function class.write_automaton(out, automaton)
  out:write([[
digraph g {
graph [rankdir=LR];
]])
  for state = 1, automaton.max_state do
    if state == automaton.start_state or automaton.accept_states[state] then
      out:write(("%d ["):format(state))
      if state == automaton.start_state then
        out:write("style=filled,fillcolor=black,fontcolor=white,")
      end
      local accept = automaton.accept_states[state]
      if accept then
        out:write("peripheries=2,")
      end
      out:write(("label=<%d"):format(state))
      if accept then
        out:write((" / %d"):format(accept))
      end
      out:write(">];\n")
    end
  end
  if automaton.epsilons then
    for state = 1, automaton.max_state do
      local e1 = automaton.epsilons[1][state]
      local e2 = automaton.epsilons[2][state]
      if e1 then
        out:write(("%d -> %d;\n"):format(state, e1))
      end
      if e2 then
        out:write(("%d -> %d;\n"):format(state, e2))
      end
    end
  end
  for state = 1, automaton.max_state do
    local transition = {}
    for char = 0, 255 do
      local to = automaton.transitions[char][state]
      if to then
        local chars = transition[to]
        if not chars then
          chars = {}
          transition[to] = chars
        end
        chars[#chars + 1] = char
      end
    end
    for to, chars in pairs(transition) do
      out:write(("%d -> %d[label=<%s>];\n"):format(state, to, string.char(unpack(chars))))
    end
  end
  out:write([[
}
]])
  return out
end

return class
