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

local class = {}

function class.new(id, grammar)
  return {
    id = id;
    grammar = grammar;
  }
end

function class:body(...)
  self.grammar:production(self, ...)
  return self
end

function class:prec(name)
  self.grammar:prec_production(name)
  return self
end

function class:translate(max_terminal_symbol)
  return self.id + max_terminal_symbol
end

class._ = class.body

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, id, grammar)
    return setmetatable(class.new(id, grammar), class.metatable)
  end;
})
