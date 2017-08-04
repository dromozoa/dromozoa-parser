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

local encode = require "dromozoa.parser.encode"

return function (self, out)
  local max_state = self.max_state
  local actions = self.actions
  local gotos = self.gotos

  out:write("local parser = require \"dromozoa.parser.parser\"\n\n")

  local n = 0
  local data_table = {}
  local action_map = {}
  for i = 1, max_state do
    local t = actions[i]
    if t then
      local code = encode(t)
      local name = data_table[code]
      if not name then
        n = n + 1
        name = "_" .. n
        data_table[code] = name
        out:write("local ", name, " = ", code, "\n")
      end
      action_map[i] = name
    end
  end
  local goto_map = {}
  for i = 1, max_state do
    local t = gotos[i]
    if t then
      local code = encode(t)
      local name = data_table[code]
      if not name then
        n = n + 1
        name = "_" .. n
        data_table[code] = name
        out:write("local ", name, " = ", code, "\n")
      end
      goto_map[i] = name
    end
  end

  out:write("\nlocal data = {\n")

  out:write("  symbol_names = ", encode(self.symbol_names), ";\n")
  out:write("  max_state = ", encode(max_state), ";\n")
  out:write("  max_terminal_symbol = ", encode(self.max_terminal_symbol), ";\n")
  out:write("  actions = {")
  for i = 1, max_state do
    local map = action_map[i]
    if map then
      ;
    end
  end
  out:write("};\n")

  out:write("}\n\nreturn parser(data)\n")
  return out
end
