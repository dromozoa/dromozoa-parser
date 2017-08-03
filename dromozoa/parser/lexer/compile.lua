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

local function write_action(out, action)
  out:write("{")
  out:write(action[1])
  for i = 2, #action do
    local operand = action[2]
    out:write(",")
    local t = type(operand)
    if t == "number" then
      out:write(("%.17g"):format(operand))
    elseif t == "string" then
      out:write(("%q"):format(operand))
    end
  end
  out:write("};")
  return out
end

local function encode_transition(max_state, transition)
  local data = {}
  for i = 1, max_state do
    local state = transition[i]
    if state then
      data[#data + 1] = "[" .. i .. "]=" .. state
    end
  end
  return table.concat(data, ",")
end

return function (self, out)
  local lexers = self.lexers

  out:write('local lexer = require "dromozoa.parser.lexer"\n\n')

  local n = 0
  local transition_map = {}
  for i = 1, #lexers do
    local lexer = lexers[i]
    local automaton = lexer.automaton
    if automaton then
      local max_state = automaton.max_state
      local transitions = automaton.transitions
      for char = 0, 255 do
        local key = encode_transition(max_state, transitions[char])
        if not transition_map[key] then
          n = n + 1
          transition_map[key] = "_" .. n
          out:write("local _", n, " = {", key, "}\n")
        end
      end
    end
  end
  local format = " [%3d] = %" .. #("_" .. n) .. "s;"

  out:write('\nlocal lexers = {\n')

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
    out:write('  {\n')
    if automaton then
      local start_state = automaton.start_state
      local accept_states = automaton.accept_states
      local transitions = automaton.transitions
      out:write('    automaton = {\n')
      out:write('      start_state = ', start_state, ';\n')
      out:write('      transitions = {')
      for char = 0, 255 do
        if char % 8 == 0 then
          out:write('\n       ')
        end
        local key = encode_transition(max_state, transitions[char])
        out:write(format:format(char, transition_map[key]))
      end
      out:write('\n      };\n')

      out:write([[
    };
]])
    end
    out:write([[
    accept_to_actions = {
]])
    for j = 1, max_state do
      local actions = accept_to_actions[j]
      if actions then
        out:write([[
      []], j, "] = {")
        for k = 1, #actions do
          write_action(out, actions[k])
        end
        out:write(" };\n")
      end
    end
    out:write([[
    };
    accept_to_symbol = {
]])
    for j = 1, max_state do
      local symbol = accept_to_symbol[j]
      if symbol then
        out:write([[
      []], j, "] = ", symbol, ";\n")
      end
    end

    out:write([[
    };
  };
]])
  end
  out:write([[
}

return lexer(lexers)
]])
  return out
end
