-- Copyright (C) 2018,2019 Tomoyuki Fujimori <moyu@dromozoa.com>
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
-- Under Section 7 of GPL version 3, you are granted additional
-- permissions described in the GCC Runtime Library Exception, version
-- 3.1, as published by the Free Software Foundation.
--
-- You should have received a copy of the GNU General Public License
-- and a copy of the GCC Runtime Library Exception along with
-- dromozoa-parser.  If not, see <http://www.gnu.org/licenses/>.

local tonumber = tonumber
local string_byte = string.byte
local string_char = string.char
local string_find = string.find
local string_gsub = string.gsub
local string_sub = string.sub
local table_concat = table.concat

local encode_utf8
local decode_surrogate_pair

local utf8 = utf8
if utf8 then
  encode_utf8 = utf8.char
else
  local result, module = pcall(require, "dromozoa.utf8.encode")
  if result then
    encode_utf8 = module
  end
end
if not encode_utf8 then
  encode_utf8 = function (a)
    if a <= 0x7F then
      return string_char(a)
    elseif a <= 0x07FF then
      local b = a % 0x40
      local a = (a - b) / 0x40
      return string_char(a + 0xC0, b + 0x80)
    elseif a <= 0xFFFF then
      local c = a % 0x40
      local a = (a - c) / 0x40
      local b = a % 0x40
      local a = (a - b) / 0x40
      return string_char(a + 0xE0, b + 0x80, c + 0x80)
    else
      local d = a % 0x40
      local a = (a - d) / 0x40
      local c = a % 0x40
      local a = (a - c) / 0x40
      local b = a % 0x40
      local a = (a - b) / 0x40
      return string_char(a + 0xF0, b + 0x80, c + 0x80, d + 0x80)
    end
  end
end

local result, module = pcall(require, "dromozoa.utf16.decode_surrogate_pair")
if result then
  decode_surrogate_pair = module
else
  decode_surrogate_pair = function (a, b)
    return (a - 0xD800) * 0x0400 + (b - 0xDC00) + 0x010000
  end
end

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

local eol_table = {
  ["\r"] = "\n";
  ["\r\n"] = "\n";
  ["\n\r"] = "\n";
  ["\r\r"] = "\n\n";
}

local function scan(s, init, n, automaton)
  local transitions = automaton.transitions
  local state = automaton.start_state

  local position
  local accept

  for i = init + 3, n, 4 do
    local a, b, c, d = string_byte(s, i - 3, i)
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
      local a, b, c = string_byte(s, m, n)
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
  return position, accept
end

return function (self, s, use_line_number)
  local init = 1
  local n = #s
  local terminal_nodes = {}

  local stack = { 1 } -- start lexer
  local position_start = init
  local position_mark
  local buffer = {}

  local line_count = 1
  local line_start = 0

  while init <= n do
    local lexer = self[stack[#stack]]
    local automaton = lexer.automaton
    local position
    local accept

    if automaton then -- regexp_lexer
      position, accept = scan(s, init, n, automaton)
      if not accept then
        return nil, "lexer error", init
      end
    else -- search lexer
      local i, j = string_find(s, self.hold, init, true)
      if not i then
        return nil, "lexer error", init
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

    local rn = line_count
    local rc = line_start

    local actions = lexer.accept_to_actions[accept]
    for i = 1, #actions do
      local action = actions[i]
      local code = action[1]
      if code == 1 then -- skip
        skip = true
      elseif code == 2 then -- push
        buffer[#buffer + 1] = string_sub(rs, ri, rj)
        skip = true
      elseif code == 3 then -- concat
        rs = table_concat(buffer)
        ri = 1
        rj = #rs
        for j = 1, #buffer do
          buffer[j] = nil
        end
      elseif code == 4 then -- call
        stack[#stack + 1] = action[2]
      elseif code == 5 then -- return
        stack[#stack] = nil
      elseif code == 6 then -- substitute
        rs = action[2]
        ri = 1
        rj = #rs
      elseif code == 7 then -- hold
        self.hold = string_sub(rs, ri, rj)
      elseif code == 8 then -- mark
        position_mark = init
      elseif code == 9 then -- substring
        ri, rj = range(ri, rj, action[2], action[3])
      elseif code == 10 then -- convert to integer
        rv = tonumber(string_sub(rs, ri, rj), action[2])
      elseif code == 11 then -- convert to char
        rs = string_char(rv)
        ri = 1
        rj = #rs
      elseif code == 12 then -- join
        rs = action[2] .. string_sub(rs, ri, rj) .. action[3]
        ri = 1
        rj = #rs
      elseif code == 13 then -- encode utf8
        rs = encode_utf8(tonumber(string_sub(rs, range(ri, rj, action[2], action[3])), 16))
        ri = 1
        rj = #rs
      elseif code == 14 then -- encode utf8 (surrogate pair)
        local code1 = tonumber(string_sub(rs, range(ri, rj, action[2], action[3])), 16)
        local code2 = tonumber(string_sub(rs, range(ri, rj, action[4], action[5])), 16)
        rs = encode_utf8(decode_surrogate_pair(code1, code2))
        ri = 1
        rj = #rs
      elseif code == 15 then -- add integer
        rv = rv + action[2]
      elseif code == 16 then -- normalize end-of-line
        rs = string_gsub(string_gsub(string_sub(rs, ri, rj), "[\n\r][\n\r]?", eol_table), "^\n", "")
        ri = 1
        rj = #rs
      elseif code == 17 then -- update line number
        rn = rn + 1
        rc = position - 1
      end
    end

    if not skip then
      if not position_mark then
        position_mark = init
      end
      local node = {
        [0] = lexer.accept_to_symbol[accept];
        p = position_start;
        i = position_mark;
        j = position - 1;
        rs = rs;
        ri = ri;
        rj = rj;
      }
      if use_line_number then
        node.n = line_count
        node.c = position_mark - line_start
      end
      terminal_nodes[#terminal_nodes + 1] = node
      position_start = position
      position_mark = nil
    end
    init = position
    line_count = rn
    line_start = rc
  end

  if #stack == 1 then
    if not position_mark then
      position_mark = init
    end
    local node = {
      [0] = 1; -- marker end
      p = position_start;
      i = position_mark;
      j = n;
      rs = s;
      ri = init;
      rj = n;
    }
    if use_line_number then
      node.n = line_count
      node.c = position_mark - line_start
    end
    terminal_nodes[#terminal_nodes + 1] = node
    return terminal_nodes
  else
    return nil, "lexer error", init
  end
end
