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

local compile = require "dromozoa.parser.lexer.compile"
local error_message = require "dromozoa.parser.error_message"

local function range(ri, rj, i, j)
  if i > 0 then
    i = i + ri - 1
  else
    i = i + rj + 1
  end
  if j > 0 then
    j = j + ri - 1
  else
    j = j + rj + 1
  end
  return i, j
end

local utf8_char
if utf8 then
  utf8_char = utf8.char
else
  utf8_char = function (a)
    if a <= 0x7F then
      return string.char(a)
    elseif a <= 0x07FF then
      local b = a % 0x40
      local a = (a - b) / 0x40
      return string.char(a + 0xc0, b + 0x80)
    elseif a <= 0xFFFF then
      local c = a % 0x40
      local a = (a - c) / 0x40
      local b = a % 0x40
      local a = (a - b) / 0x40
      return string.char(a + 0xe0, b + 0x80, c + 0x80)
    else -- code <= 0x10FFFF
      local d = a % 0x40
      local a = (a - d) / 0x40
      local c = a % 0x40
      local a = (a - c) / 0x40
      local b = a % 0x40
      local a = (a - b) / 0x40
      return string.char(a + 0xf0, b + 0x80, c + 0x80, d + 0x80)
    end
  end
end

local class = {}
local metatable = {
  __index = class;
}
class.metatable = metatable

function class:compile(out)
  if type(out) == "string" then
    compile(self, assert(io.open(out, "w"))):close()
  else
    return compile(self, out)
  end
end

function metatable:__call(s, file)
  local lexers = self.lexers

  local init = 1
  local n = #s
  local terminal_nodes = {}

  local stack = { 1 } -- start lexer
  local position_start = init
  local position_mark
  local buffer = {}

  while init <= n do
    local lexer = lexers[stack[#stack]]
    local automaton = lexer.automaton
    local position
    local accept

    if automaton then -- regexp_lexer
      local transitions = automaton.transitions
      local state = automaton.start_state

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

      accept = automaton.accept_states[state]
      if not accept then
        return nil, error_message("lexer error", s, init, file)
      end
    else -- search lexer
      local i, j = s:find(self.hold, init, true)
      if not i then
        return nil, error_message("lexer error", s, init, file)
      end
      if init == i then
        position = j + 1
        accept = 1
      else
        position = i
        accept = 2
      end
    end

    local skip
    local rs = s
    local ri = init
    local rj = position - 1
    local rv

    local actions = lexer.accept_to_actions[accept]
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
      elseif code == 8 then -- substitute
        rs = action[2]
        ri = 1
        rj = #rs
      elseif code == 9 then -- hold
        self.hold = rs:sub(ri, rj)
      elseif code == 10 then -- mark
        position_mark = init
      elseif code == 11 then -- substring
        ri, rj = range(ri, rj, action[2], action[3])
      elseif code == 12 then -- convert to integer
        rv = tonumber(rs:sub(ri, rj), action[2])
      elseif code == 13 then -- convert to char
        rs = string.char(rv)
        ri = 1
        rj = #rs
      elseif code == 14 then -- join
        rs = action[2] .. rs:sub(ri, rj) .. action[3]
        ri = 1
        rj = #rs
      elseif code == 15 then -- encode utf8
        local i, j = range(ri, rj, action[2], action[3])
        local code = tonumber(rs:sub(i, j), 16)
        rs = utf8_char(code)
        ri = 1
        rj = #rs
      elseif code == 16 then -- encode utf8 (surrogate pair)
        local i, j = range(ri, rj, action[2], action[3])
        local code1 = tonumber(rs:sub(i, j), 16) % 0x0400 * 0x0400
        local i, j = range(ri, rj, action[4], action[5])
        local code2 = tonumber(rs:sub(i, j), 16) % 0x0400
        rs = utf8_char(code1 + code2 + 0x010000)
        ri = 1
        rj = #rs
      elseif code == 17 then -- add integer
        rv = rv + action[2]
      end
    end

    if not skip then
      if not position_mark then
        position_mark = init
      end
      terminal_nodes[#terminal_nodes + 1] = {
        [0] = lexer.accept_to_symbol[accept];
        n = 0;
        p = position_start;
        i = position_mark;
        j = position - 1;
        rs = rs;
        ri = ri;
        rj = rj;
      }
      position_start = position
      position_mark = nil
    end
    init = position
  end

  if #stack == 1 then
    if not position_mark then
      position_mark = init
    end
    terminal_nodes[#terminal_nodes + 1] = {
      [0] = 1; -- marker end
      n = 0;
      p = position_start;
      i = position_mark;
      j = n;
      rs = s;
      ri = init;
      rj = n;
    }
    return terminal_nodes
  else
    return nil, error_message("lexer error", s, init, file)
  end
end

return setmetatable(class, {
  __call = function (_, lexers)
    return setmetatable({ lexers = lexers }, metatable)
  end;
})
