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

local resolution_table = {
  ") conflict resolved as shift";
  ") conflict resolved as reduce";
  ") conflict resolved as an error";
}

return function (self, out, conflicts, verbose)
  local symbol_names = self.symbol_names
  local productions = self.productions
  for i = 1, #conflicts do
    local conflict = conflicts[i]
    if not conflict.resolved or verbose then
      local first = conflict[1]
      local first_action = first.action
      local second = conflict[2]
      if first_action == 1 then
        out:write("shift(", first.argument,") / reduce(", second.argument, resolution_table[conflict.resolution])
        local precedence = second.precedence
        if precedence > 0 then
          local shift_precedence = first.precedence
          out:write(": precedence ", shift_precedence)
          if shift_precedence == precedence then
            out:write(" == ", precedence, " associativity ", second.associativity)
          else
            if shift_precedence < precedence then
              out:write(" < ")
            else
              out:write(" > ")
            end
            out:write(precedence)
          end
        end
      elseif first_action == 2 then
        out:write("reduce(", first.argument, ") / reduce(", second.argument, ") conflict")
      else
        out:write("error / reduce(", second.argument, resolution_table[3])
      end
      out:write(" at state(", conflict.state, ") symbol(", symbol_names[conflict.symbol], ")\n")
    end
  end
  return out
end
