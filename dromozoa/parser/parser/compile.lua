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
  local data = {
    symbol_names = self.symbol_names;
    symbol_table = self.symbol_table;
    max_state = self.max_state;
    max_terminal_symbol = self.max_terminal_symbol;
    actions = self.actions;
    gotos = self.gotos;
    heads = self.heads;
    sizes = self.sizes;
    reduce_to_semantic_action = self.reduce_to_semantic_action;
    reduce_to_attribute_actions = self.reduce_to_attribute_actions;
  }
  out:write("local parser = require \"dromozoa.parser.parser\"\n")
  local root = dumper():dump(out, data)
  out:write("return function () return parser(", root,") end\n")
  return out
end
