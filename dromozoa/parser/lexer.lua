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
    buffer = {};
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
  local buffer = self.buffer

  while true do
    if #s < init then
      return 1, init, s, init, init -- marker end
    end

    local lexer = lexers[stack[#stack]]
    local items = lexer.items
    local accept_table = lexer.accept_table
    local automaton = lexer.automaton
    local transitions = automaton.transitions
    local accept_states = automaton.accept_states

    local state = automaton.start_state
    for pos = init, #s + 1 do
      local next_state
      if pos <= #s then
        local byte = s:byte(pos)
        next_state = transitions[byte][state]
      end
      if not next_state then
        local accept = accept_states[state]
        if accept then
          local actions = items[accept].actions
          local skip

          local s = s
          local ri = init
          local rj = pos - 1

          for j = 1, #actions do
            local action = actions[j]
            local code = action[1]
            if code == 1 then -- skip
              skip = true
            elseif code == 2 then -- push
              buffer[#buffer + 1] = s:sub(ri, rj)
              skip = true
            elseif code == 3 then -- concat
              s = table.concat(buffer)
              ri = 1
              rj = #s
              for i = 1, #buffer do
                buffer[i] = nil
              end
            elseif code == 4 then -- call
              stack[#stack + 1] = action[2]
            elseif code == 5 then -- return
              stack[#stack] = nil
            elseif code == 6 then -- filter table
              s = action[2][s:sub(ri, rj)]
              ri = 1
              rj = #s
            elseif code == 7 then -- filter function
              s, ri, rj = action[2](s, ri, rj)
              if not ri then
                ri = 1
              end
              if not rj then
                rj = #s
              end
            elseif code == 8 then -- replace
              s = action[2]
              ri = 1
              rj = #s
            end
          end

          if skip then
            init = pos
            break
          else
            return accept_table[accept], pos, s, ri, rj
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
