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

local char_table = {
  -- Control Escape
  [0x0C] = "\\f";
  [0x0A] = "\\n";
  [0x0D] = "\\r";
  [0x09] = "\\t";
  [0x0B] = "\\v";

  -- Syntax Character
  [0x5E] = "\\^";
  [0x24] = "\\$";
  [0x5C] = "\\\\";
  [0x2E] = "\\.";
  [0x2A] = "\\*";
  [0x2B] = "\\+";
  [0x3F] = "\\?";
  [0x28] = "\\(";
  [0x29] = "\\)";
  [0x5B] = "\\[";
  [0x5D] = "\\]";
  [0x7B] = "\\{";
  [0x7D] = "\\}";
  [0x7C] = "\\|";
}

for byte = 0x00, 0xFF do
  if not char_table[byte] then
    if 0x20 <= byte and byte <= 0x7E then
      char_table[byte] = string.char(byte)
    else
      char_table[byte] = ("\\x%02X"):format(byte)
    end
  end
end

local range_char_table = setmetatable({
  [0x2D] = "\\-";
}, { __index = char_table })

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
      if n == 1 then
        for k, v in pairs(item) do
          if k ~= "n" then
            label = char_table[k]
            break
          end
        end
      elseif n == 256 then
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
            buffer[#buffer + 1] = range_char_table[byte1]
          else
            buffer[#buffer + 1] = range_char_table[byte1] .. "-" .. range_char_table[byte2]
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
