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

local char_table = {}
for char = 0, 255 do
  char_table[char] = ([[\\x%02x]]):format(char)
end
for char = 32, 126 do
  char_table[char] = string.char(char)
end
char_table[0x09] = [=[\\t]=]
char_table[0x0a] = [=[\\n]=]
char_table[0x0b] = [=[\\v]=]
char_table[0x0c] = [=[\\f]=]
char_table[0x0d] = [=[\\r]=]
char_table[0x22] = [=[\"]=]
char_table[0x5b] = [=[\\[]=]
char_table[0x5c] = [=[\\\\]=]
char_table[0x5d] = [=[\\]]=]
char_table[0x5e] = [=[\\^]=]

return function (this, out)
  local epsilons = this.epsilons
  local transitions = this.transitions
  local start_state = this.start_state
  local accept_states = this.accept_states

  out:write([[
digraph g {
graph [rankdir=LR];
]])

  for u, accept in pairs(accept_states) do
    out:write(u, " [peripheries=2")
    if u == start_state then
      out:write(",style=filled,fillcolor=black,fontcolor=white")
    end
    out:write(',label="', u, " / ", accept, '"];\n')
  end

  if not accept_states[start_state] then
    out:write(start_state, '[style=filled,fillcolor=black,fontcolor=white,label="', start_state, '"];\n')
  end

  if epsilons then
    for u, v in pairs(epsilons[1]) do
      out:write(u, " -> ", v, "\n")
    end
    for u, v in pairs(epsilons[2]) do
      out:write(u, " -> ", v, "\n")
    end
  end

  for u = 1, this.max_state do
    local map = {}
    for char = 0, 255 do
      local v = transitions[char][u]
      if v then
        local item = map[v]
        if item then
          item.set[char] = true
          item.n = item.n + 1
        else
          map[v] = {
            set = { [char] = true };
            n = 1;
          }
        end
      end
    end

    for v, item in pairs(map) do
      local n = item.n
      if n == 256 then
        out:write(u, "->", v, '[label="."];\n')
      else
        local set = item.set
        local neg = n > 127

        local ranges = {}
        if neg then
          for char = 0, 255 do
            if not set[char] then
              local range = ranges[#ranges]
              if range and range[2] + 1 == char then
                range[2] = char
              else
                ranges[#ranges + 1] = { char, char }
              end
            end
          end
        else
          for char = 0, 255 do
            if set[char] then
              local range = ranges[#ranges]
              if range and range[2] + 1 == char then
                range[2] = char
              else
                ranges[#ranges + 1] = { char, char }
              end
            end
          end
        end

        out:write(u, " -> ", v, ' [label="[')
        if neg then
          out:write("^")
        end

        for i = 1, #ranges do
          local range = ranges[i]
          local char1, char2 = range[1], range[2]
          if char1 == char2 then
            out:write(char_table[char1])
          else
            out:write(char_table[char1], "-", char_table[char2])
          end
        end
        out:write(']"];\n')
      end
    end
  end
  out:write([[
}
]])

  return out
end
