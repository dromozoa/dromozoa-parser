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

local class = {}
local metatable = {
  __index = class;
}
class.metatable = metatable

function metatable:__call(s, init)
  if not init then
    init = 1
  end

  local lexers = self.lexers
  local stack = self.stack
  local buffer = self.buffer

  local n = #s

  while true do
    if n < init then
      if #stack == 1 then
        return 1, init, s, init, init -- marker end
      else
        return nil, ("lexer error at position %d"):format(init)
      end
    end

    local lexer = lexers[stack[#stack]]
    local items = lexer.items
    local automaton = lexer.automaton
    local transitions = automaton.transitions

    local state = automaton.start_state
    local position

    for i = init + 3, n, 4 do
      local a, b, c, d = s:byte(i - 3, i)
      local state1 = transitions[a][state]
      if not state1 then
        position = i - 3
        break
      else
        local state2 = transitions[b][state1]
        if not state2 then
          state = state1
          position = i - 2
          break
        else
          local state3 = transitions[c][state2]
          if not state3 then
            state = state2
            position = i - 1
            break
          else
            local state4 = transitions[d][state3]
            if not state4 then
              state = state3
              position = i
              break
            else
              state = state4
            end
          end
        end
      end
    end

    if not position then
      position = n + 1
      local m = position - (position - init) % 4
      if m < position then
        local a, b, c = s:byte(m, n)
        if c then
          local state1 = transitions[a][state]
          if not state1 then
            position = m
          else
            local state2 = transitions[b][state1]
            if not state2 then
              state = state1
              position = m + 1
            else
              local state3 = transitions[c][state2]
              if not state3 then
                state = state2
                position = n
              else
                state = state3
              end
            end
          end
        elseif b then
          local state1 = transitions[a][state]
          if not state1 then
            position = m
          else
            local state2 = transitions[b][state1]
            if not state2 then
              state = state1
              position = m + 1
            else
              state = state2
            end
          end
        else
          local state1 = transitions[a][state]
          if not state1 then
            position = m
          else
            state = state1
          end
        end
      end
    end

    local accept = automaton.accept_states[state]
    if not accept then
      return nil, ("lexer error at position %d"):format(init)
    end

    local actions = items[accept].actions
    local skip
    local rs = s
    local ri = init
    local rj = position - 1

    for i = 1, #actions do
      local action = actions[i]
      local code = action[1]
      if code == 1 then -- skip
        skip = true
      elseif code == 2 then -- push
        buffer[#buffer + 1] = rs:sub(ri, rj)
        skip = true
      elseif code == 3 then -- concat
        rs = table.concat(buffer)
        ri = 1
        rj = #rs
        for j = 1, #buffer do
          buffer[j] = nil
        end
      elseif code == 4 then -- call
        stack[#stack + 1] = action[2]
      elseif code == 5 then -- return
        stack[#stack] = nil
      elseif code == 6 then -- filter table
        rs = action[2][rs:sub(ri, rj)]
        ri = 1
        rj = #rs
      elseif code == 7 then -- filter function
        rs, ri, rj = action[2](rs, ri, rj)
        if not ri then
          ri = 1
        end
        if not rj then
          rj = #rs
        end
      elseif code == 8 then -- replace
        rs = action[2]
        ri = 1
        rj = #rs
      end
    end
    if skip then
      init = position
    else
      return lexer.accept_to_symbol[accept], position, rs, ri, rj
    end
  end
end

return setmetatable(class, {
  __call = function (_, lexers)
    return setmetatable({
      lexers = lexers;
      stack = { 1 }; -- start lexer
      buffer = {};
    }, metatable)
  end;
})
