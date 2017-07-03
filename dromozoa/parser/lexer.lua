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

local function compile(lexers)
  return {
    lexers = lexers;
    stack = { 1 }; -- start lexer
  }
end

local class = {}
local metatable = {
  __index = class;
}
class.metatable = metatable

function metatable:__call(s, init)
  local lexers = self.lexers
  local stack = self.stack

  while true do
    if #s < init then
      return 1, init, init -- marker end
    end

    local lexer = lexers[stack[#stack]]
    local items = lexer.items
    local automaton = lexer.automaton
    local accept_table = lexer.accept_table
    local transitions = automaton.transitions
    local accept_states = automaton.accept_states

    local state = automaton.start_state
    for i = init, #s + 1 do
      local next_state
      if i <= #s then
        local byte = s:byte(i)
        next_state = transitions[byte][state]
      end
      if not next_state then
        local accept = accept_states[state]
        if accept then
          local item = items[accept]
          local operator = item.operator
          if operator == 2 then -- call
            stack[#stack + 1] = item.operand
          elseif operator == 3 then -- ret
            stack[#stack] = nil
          end
          local action = item.action
          if action == 1 then -- default
            return accept_table[accept], init, i - 1
          elseif action == 2 then -- skip
            init = i
            break
          end
        else
          return nil, "lexer error", init
        end
      else
        state = next_state
      end
    end
  end
end

return setmetatable(class, {
  __call = function (_, lexers)
    return setmetatable(compile(lexers), metatable)
  end;
})
