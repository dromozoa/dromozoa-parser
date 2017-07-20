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

return function (self, out, transitions)
  local symbol_names = self.symbol_names
  out:write('digraph g {\ngraph [rankdir=LR];\n')
  for from, transition in pairs(transitions) do
    for symbol, to in pairs(transition) do
      -- [TODO] escape xml
      -- [TODO] make table
      -- [TODO] check textbook
      out:write(from, '->', to, ' [label="', symbol_names[symbol], '"];\n')
    end
  end
  out:write('}\n')
  return out
end
