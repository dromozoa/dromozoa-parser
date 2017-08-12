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

local dumper = require "dromozoa.parser.dumper"

return function (self, out)
  local lexers = self.lexers
  local data = {}
  for i = 1, #lexers do
    local lexer = lexers[i]
    data[#data + 1] = {
      automaton = lexer.automaton;
      accept_states = lexer.accept_states;
      accept_to_actions = lexer.accept_to_actions;
      accept_to_symbol = lexer.accept_to_symbol;
    }
  end
  out:write("local lexer = require \"dromozoa.parser.lexer\"\n")
  local root = dumper():dump(out, data)
  out:write("return function () return lexer(", root, ") end\n")
  return out
end
