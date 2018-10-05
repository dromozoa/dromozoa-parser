-- Copyright (C) 2017,2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local compile = require "dromozoa.parser.parser.compile"
local execute = require "dromozoa.parser.parser.execute"

local class = {}
local metatable = {
  __index = class;
  __call = execute;
}

function class:compile(out)
  if type(out) == "string" then
    compile(self, assert(io.open(out, "w"))):close()
  else
    return compile(self, out)
  end
end

return setmetatable(class, {
  __call = function (_, data)
    return setmetatable({
      symbol_names = data.symbol_names;
      symbol_table = data.symbol_table;
      max_state = data.max_state;
      max_terminal_symbol = data.max_terminal_symbol;
      actions = data.actions;
      gotos = data.gotos;
      heads = data.heads;
      sizes = data.sizes;
      reduce_to_semantic_action = data.reduce_to_semantic_action;
      reduce_to_attribute_actions = data.reduce_to_attribute_actions;
    }, metatable)
  end
})
