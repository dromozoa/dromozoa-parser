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

local TO = string.char(0xE2, 0x86, 0x92) -- U+2192 RIGHWARDS ARROW
local DOT = string.char(0xC2, 0xB7) -- U+00B7 MIDDLE DOT

return function (self, out, set_of_items)
  local symbol_names = self.symbol_names
  local productions = self.productions
  for i = 1, #set_of_items do
    local items = set_of_items[i]
    out:write("======== I_", i, " ==========\n")
    for j = 1, #items do
      local item = items[j]
      local production = productions[item.id]
      local body = production.body
      local dot = item.dot
      local la = item.la
      out:write(symbol_names[production.head], " ", TO)
      for k = 1, #body do
        if k == dot then
          out:write(" ", DOT)
        end
        out:write(" ", symbol_names[body[k]])
      end
      if dot == #body + 1 then
        out:write(" ", DOT)
      end
      if la then
        out:write(", ", symbol_names[la])
      end
      out:write("\n")
    end
  end
  return out
end
