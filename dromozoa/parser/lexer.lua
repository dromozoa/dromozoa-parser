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

local compile = require "dromozoa.parser.lexer.compile"
local execute = require "dromozoa.parser.lexer.execute"

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
    local self = {}
    for i = 1, #data do
      local lexer = data[i]
      self[i] = {
        automaton = lexer.automaton;
        accept_states = lexer.accept_states;
        accept_to_actions = lexer.accept_to_actions;
        accept_to_symbol = lexer.accept_to_symbol;
      }
    end
    return setmetatable(self, metatable)
  end;
})
