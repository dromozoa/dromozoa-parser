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

local encode = require "dromozoa.parser.encode"

return function (self, out)
  local lexers = self.lexers

  out:write("local lexer = require \"dromozoa.parser.lexer\"\n\n")

  out:write("local _0 = {}\n")

  local n = 0
  local data_table = {}
  local transition_map = {}
  for i = 1, #lexers do
    local lexer = lexers[i]
    local automaton = lexer.automaton
    if automaton then
      local transitions = automaton.transitions
      local map = {}
      for char = 0, 255 do
        local code = encode(transitions[char])
        local name = data_table[code]
        if not name then
          n = n + 1
          name = "_" .. n
          data_table[code] = name
          out:write("local ", name, " = ", code, "\n")
        end
        map[char] = name
      end
      transition_map[i] = map
    end
  end

  out:write("\nlocal lexers = {\n")

  for i = 1, #lexers do
    local lexer = lexers[i]
    local automaton = lexer.automaton
    local accept_to_actions = lexer.accept_to_actions
    local accept_to_symbol = lexer.accept_to_symbol
    local max_state
    if automaton then -- regexp lexer
      max_state = automaton.max_state
    else -- search lexer
      max_state = 2
    end
    out:write("  {\n")
    if automaton then
      local start_state = automaton.start_state
      local transitions = automaton.transitions
      local map = transition_map[i]
      out:write("    automaton = {\n      max_state = ", encode(max_state), ";\n      start_state = ", encode(automaton.start_state), ";\n      transitions = {")
      for char = 0, 255 do
        if char > 0 then
          out:write(",")
        end
        out:write("[", char, "]=", map[char])
      end
      out:write("};\n      accept_states = ", encode(automaton.accept_states), ";\n    };\n")
    end
    out:write("    accept_to_actions = {\n")
    for j = 1, max_state do -- [FIX] max_state not suitable
      local actions = accept_to_actions[j]
      if actions then
        if actions[1] then
          out:write("       ", encode(actions), ";\n")
        else
          out:write("       _0;\n")
        end
      end
    end
    out:write("    };\n    accept_to_symbol = ", encode(accept_to_symbol), ";\n  };\n")
  end

  out:write("}\n\nreturn lexer(lexers)\n")
  return out
end
