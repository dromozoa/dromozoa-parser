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
local grammar = require "dromozoa.parser.grammar"
local nonterminal_symbol = require "dromozoa.parser.builder.nonterminal_symbol"
local symbol_table = require "dromozoa.parser.builder.symbol_table"
local terminal_symbol = require "dromozoa.parser.builder.terminal_symbol"

local class = {}

function class.new(terminal_symbols)
  if terminal_symbols == nil then
    terminal_symbols = symbol_table()
    terminal_symbols.n = 1
    terminal_symbols[1] = "$"
  end
  return {
    terminal_symbols = terminal_symbols;
    nonterminal_symbols = symbol_table();
    productions = sequence();
    precedence = 0;
    precedence_n = 0;
    precedence_names = {};
    precedences = {};
    associativities = {};
  }
end

function class:precedence_impl(associativity, ...)
  local terminal_symbols = self.terminal_symbols
  local precedence_names = self.precedence_names
  local precedences = self.precedences
  local associativities = self.associativities

  local precedence = self.precedence + 1
  self.precedence = precedence

  local names = sequence():push(...)
  for name in names:each() do
    local id = precedence_names[name]
    if id == nil then
      id = terminal_symbols:symbol(name)
      precedence_names[name] = id
    end
    precedences[id] = precedence
    associativities[id] = associativity
  end

  return self
end

function class:prec(name)
  local n = self.precedence_n - 1
  self.precedence_n = n
  self.precedence_names[name] = n
  return name
end

function class:left(...)
  return self:precedence_impl("left", ...)
end

function class:right(...)
  return self:precedence_impl("right", ...)
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

function class:prec_production(name)
  local production = self.productions:top()
  local id = assert(self.precedence_names[name])
  production.precedence = self.precedences[id]
  production.associativity = self.associativities[id]
end

function class:build(start_symbol)
  local terminal_symbols = self.terminal_symbols
  local nonterminal_symbols = self.nonterminal_symbols
  local productions = self.productions

  if start_symbol == nil then
    start_symbol = productions[1].head
  end

  local argumented_start_symbol_id = nonterminal_symbols.n + 1
  nonterminal_symbols.n = argumented_start_symbol_id
  nonterminal_symbols[argumented_start_symbol_id] = nonterminal_symbols[start_symbol.id] .. "'"
  local argumented_start_symbol = nonterminal_symbol(argumented_start_symbol_id, self)

  local max_terminal_symbol = terminal_symbols:max()

  local production_precedences = {}
  local production_associativities = {}

  local head = argumented_start_symbol:translate(max_terminal_symbol)
  local body = sequence():push(start_symbol:translate(max_terminal_symbol))
  local productions = sequence():push({ head = head, body = body })
  for id, production in ipairs(self.productions) do
    local head = production.head:translate(max_terminal_symbol)
    local body = sequence()
    for symbol in production.body:each() do
      body:push(symbol:translate(max_terminal_symbol))
    end
    productions:push({ head = head, body = body })
    -- inc for extended
    production_precedences[id + 1] = production.precedence
    production_associativities[id + 1] = production.associativity
  end

  local symbols = sequence()
  for id, name in terminal_symbols:each() do
    symbols[id] = name
  end
  for id, name in nonterminal_symbols:each() do
    symbols[id + max_terminal_symbol] = name
  end

  return grammar(
      productions,
      symbols,
      max_terminal_symbol,
      argumented_start_symbol:translate(max_terminal_symbol),
      self.precedences,
      self.associativities,
      production_precedences,
      production_associativities)
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
  __call = function (_, terminal_symbols)
    return setmetatable(class.new(terminal_symbols), class.metatable)
  end;
})
