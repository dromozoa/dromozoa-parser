-- Copyright (C) 2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local graph = require "dromozoa.graph"

local char_table = {}
for byte = 0, 255 do
  char_table[byte] = ([[\\x%02x]]):format(byte)
end
for byte = 32, 126 do
  char_table[byte] = string.char(byte)
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

return function (this)
  local max_state = this.max_state
  local epsilons = this.epsilons
  local transitions = this.transitions

  local that = graph()

  for u = 1, max_state do
    that:add_vertex()
  end

  if epsilons then
    for u, v in pairs(epsilons[1]) do
      that:add_edge(u, v)
    end
    for u, v in pairs(epsilons[2]) do
      that:add_edge(u, v)
    end
  end

  local e_labels = {}

  for u = 1, max_state do
    local map = {}
    for byte = 0, 255 do
      local v = transitions[byte][u]
      if v then
        local item = map[v]
        if item then
          item.n = item.n + 1
          item[byte] = true
        else
          map[v] = { n = 1, [byte] = true }
        end
      end
    end
    for v, item in pairs(map) do
      local n = item.n
      local label
      if n == 256 then
        label = "."
      else
        local neg = n > 127

        local ranges = {}
        for byte = 0, 255 do
          local flag = item[byte]
          if neg then
            flag = not flag
          end
          if flag then
            local range = ranges[#ranges]
            if range and range[2] + 1 == byte then
              range[2] = byte
            else
              ranges[#ranges + 1] = { byte, byte }
            end
          end
        end
        local buffer = {}
        for i = 1, #ranges do
          local range = ranges[i]
          local byte1, byte2 = range[1], range[2]
          if byte1 == byte2 then
            buffer[#buffer + 1] = char_table[byte1]
          else
            buffer[#buffer + 1] = char_table[byte1] .. "-" .. char_table[byte2]
          end
        end
        label = "[" .. table.concat(buffer) .. "]"
      end
      local eid = that:add_edge(u, v)
      e_labels[eid] = label
    end
  end

  return that, e_labels
end
