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
local pairs = require "dromozoa.commons.pairs"
local sequence = require "dromozoa.commons.sequence"
local nonterminal_symbol = require "dromozoa.parser.builder.nonterminal_symbol"
local symbol_table = require "dromozoa.parser.builder.symbol_table"
local terminal_symbol = require "dromozoa.parser.builder.terminal_symbol"

local class = {}

function class.new()
  return {
    terminal_symbols = symbol_table();
    nonterminal_symbols = symbol_table();
    productions = sequence();
  }
end

function class:terminal_symbol(name)
  return terminal_symbol(self.terminal_symbols:symbol(name))
end

function class:nonterminal_symbol(name)
  return nonterminal_symbol(self.nonterminal_symbols:symbol(name), self)
end

function class:production(head, ...)
  local body = sequence():push(...)
  for i, symbol in ipairs(body) do
    if type(symbol) == "string" then
      body[i] = self:terminal_symbol(symbol)
    end
  end
  self.productions:push({ head = head, body = body })
  return self
end

function class:build(start_symbol)
  local terminal_symbols = self.terminal_symbols
  local nonterminal_symbols = self.nonterminal_symbols
  local productions = self.productions

  if start_symbol == nil then
    start_symbol = productions[1].head
  end

  local max_terminal_symbol = terminal_symbols.n

  local productions = sequence()
  for production in self.productions:each() do
    local body = sequence()
    for symbol in production.body:each() do
      body:push(symbol:translate(max_terminal_symbol))
    end
    productions:push({
      head = production.head:translate(max_terminal_symbol);
      body = body;
    })
  end

  local symbols = {}
  for name, id in pairs(terminal_symbols.map) do
    symbols[id] = name
  end
  for name, id in pairs(nonterminal_symbols.map) do
    symbols[id + max_terminal_symbol] = name
  end

  return {
    start_symbol = start_symbol:translate(max_terminal_symbol);
    productions = productions;
    symbols = symbols;
    max_terminal_symbol = max_terminal_symbol;
  }
end

class.metatable = {
  __index = class;
}

function class.metatable:__call(symbol)
  if type(symbol) == "string" then
    return self:nonterminal_symbol(symbol)
  else
    return self:build(symbol)
  end
end

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), class.metatable)
  end;
})
