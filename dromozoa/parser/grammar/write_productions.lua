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

return function (self, out)
  local symbol_names = self.symbol_names
  local productions = self.productions
  for i = 1, #productions do
    local production = productions[i]
    local body = production.body
    out:write("(", i, ") ", symbol_names[production.head], " ", TO)
    for j = 1, #body do
      out:write(" ", symbol_names[body[j]])
    end
    out:write("\n")
  end
  return out
end
