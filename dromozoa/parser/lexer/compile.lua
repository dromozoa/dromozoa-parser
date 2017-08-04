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

local function encode(value)
  local t = type(value)
  if t == "number" then
    return ("%.17g"):format(value)
  elseif t == "string" then
    return ("%q"):format(value)
  elseif t == "table" then
    local min
    local max
    local n = 0
    for k in pairs(value) do
      assert(type(k) == "number" and k % 1 == 0)
      if not min or min > k then
        min = k
      end
      if not max or max < k then
        max = k
      end
      n = n + 1
    end
    if not min then
      return "{}"
    end
    local data = {}
    if min < 1 or n * 1.8 < max then
      for i = min, max do
        local v = value[i]
        if v then
          data[#data + 1] = "[" .. i .. "]=" .. encode(v)
        end
      end
    else
      for i = 1, max do
        local v = value[i]
        if v then
          data[#data + 1] = encode(v)
        else
          data[#data + 1] = "nil"
        end
      end
    end
    return "{" .. table.concat(data, ",") .. "}"
  end
end

return function (self, out)
  local lexers = self.lexers

  out:write("local lexer = require \"dromozoa.parser.lexer\"\n")
  out:write("\n")

  local transition_table = {}
  local transition_map = {}
  local n = 0

  for i = 1, #lexers do
    local lexer = lexers[i]
    local automaton = lexer.automaton
    if automaton then
      local transitions = automaton.transitions
      local map = {}
      for char = 0, 255 do
        local key = encode(transitions[char])
        local name = transition_table[key]
        if not name then
          n = n + 1
          name = "_" .. n
          transition_table[key] = name
          out:write("local _", n, " = ", key, "\n")
        end
        map[char] = name
      end
      transition_map[i] = map
    end
  end

  out:write("\n")
  out:write("local lexers = {\n")

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
      out:write("    automaton = {\n")
      out:write("      max_state = ", encode(automaton.max_state), ";\n")
      out:write("      start_state = ", encode(automaton.start_state), ";\n")
      out:write("      transitions = {")
      for char = 0, 255 do
        if char > 0 then
          out:write(",")
        end
        out:write("[", char, "]=", map[char])
      end
      out:write("};\n")
      out:write("      accept_states = ", encode(automaton.accept_states), ";\n")
      out:write("    };\n")
    end
    out:write("    accept_to_actions = {\n")
    for j = 1, max_state do
      local actions = accept_to_actions[j]
      if actions then
        out:write("       [", j, "] = ", encode(actions), ";\n")
      end
    end
    out:write("    };\n")
    out:write("    accept_to_symbol = ", encode(accept_to_symbol), ";\n")
    out:write("  };\n")
  end
  out:write("}\n")
  out:write("\n")
  out:write("return lexer(lexers)\n")
  return out
end
