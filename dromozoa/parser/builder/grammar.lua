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

local ipairs = require "dromozoa.commons.ipairs"
local sequence = require "dromozoa.commons.sequence"
local nonterminal_symbol = require "dromozoa.parser.builder.nonterminal_symbol"
local symbol = require "dromozoa.parser.builder.symbol"
local symbol_table = require "dromozoa.parser.builder.symbol_table"

local class = {}

function class.new()
  return {
    terminal_symbols = symbol_table();
    nonterminal_symbols = symbol_table();
    productions = sequence();
  }
end

function class:terminal_symbol(name)
  return symbol("terminal", self.terminal_symbols:symbol(name), name)
end

function class:nonterminal_symbol(name)
  return nonterminal_symbol("nonterminal", self.nonterminal_symbols:symbol(name), name, self)
end

function class:production(...)
  local production = sequence():push(...)
  for i, symbol in ipairs(production) do
    if type(symbol) == "string" then
      production[i] = self:terminal_symbol(symbol)
    end
  end
  self.productions:push(production)
  return self
end

class.metatable = {
  __index = class;
  __call = class.nonterminal_symbol;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), class.metatable)
  end;
})
