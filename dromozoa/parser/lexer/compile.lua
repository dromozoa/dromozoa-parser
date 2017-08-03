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
    elseif t == "table" then
      error("not impl") -- TODO
    end
  end
  out:write("};")
  return out
end

return function (self, out)
  local lexers = self.lexers

  out:write([[
local lexer = require "dromozoa.parser.lexer"

local lexers = {
]])

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
    out:write([[
  {
]])
    if automaton then
      local transitions = automaton.transitions
      local accept_states = automaton.accept_states
      out:write([[
    automaton = {
      start_state = ]], automaton.start_state, [[;
      transitions = {
]])
      for j = 0, 255 do
        local transition = transitions[j]
        out:write("        [", j, "] = {")
        for k = 1, max_state do
          local v = transition[k]
          if v then
            out:write("[", k, "]=", v, ",")
          end
        end
        out:write("};\n")
      end

      out:write([[
      };
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
