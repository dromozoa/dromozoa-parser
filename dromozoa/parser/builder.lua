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

local clone = require "dromozoa.commons.clone"
local ipairs = require "dromozoa.commons.ipairs"
local sequence = require "dromozoa.commons.sequence"
local grammar = require "dromozoa.parser.grammar"
local precedence_builder = require "dromozoa.parser.precedence_builder"
local production_builder = require "dromozoa.parser.production_builder"
local scanner = require "dromozoa.parser.scanner"
local scanner_builder = require "dromozoa.parser.scanner_builder"
local writer = require "dromozoa.parser.writer"

local class = {}

function class.new()
  return {
    scanner_builders = sequence():push(scanner_builder());
    precedence_builder = precedence_builder();
    production_builders = sequence();
  }
end

function class:scanner(name)
  local scanner_builders = self.scanner_builders
  if name == nil then
    return scanner_builders[1]
  end
  local scanner_builder = scanner_builder(name)
  scanner_builders:push(scanner_builder)
  return scanner_builder
end

function class:lit(literal)
  return self:scanner():lit(literal)
end

function class:pat(pattern)
  return self:scanner():pat(pattern)
end

function class:left(name)
  return self.precedence_builder:left(name)
end

function class:right(name)
  return self.precedence_builder:right(name)
end

function class:nonassoc(name)
  return self.precedence_builder:nonassoc(name)
end

function class:build(start_name)
  local scanner_builders = self.scanner_builders
  local precedence_builder = self.precedence_builder
  local production_builders = self.production_builders

  if start_name == nil then
    start_name = production_builders[1].head
  end

  local n = 1
  local symbol_names = { "$" }
  local symbol_table = {}

  local scanner_names = {}
  local scanner_table = {}

  for i, scanner_builder in ipairs(scanner_builders) do
    local name = scanner_builder.name
    if name ~= nil then
      scanner_names[i] = name
      scanner_table[name] = i
    end
    local check_table = {}
    for item in scanner_builder.items:each() do
      if item.action ~= "ignore" then
        local name = item.name
        if check_table[name] ~= nil then
          error(("terminal symbol %q already defined"):format(name))
        end
        check_table[name] = true
        if symbol_table[name] == nil then
          n = n + 1
          symbol_names[n] = name
          symbol_table[name] = n
        end
      end
    end
  end

  local max_terminal_symbol = n

  -- argumented start symbol
  n = n + 1
  symbol_names[n] = start_name .. "'"

  for production in production_builders:each() do
    local name = production.head
    local symbol = symbol_table[name]
    if symbol == nil then
      n = n + 1
      symbol_names[n] = name
      symbol_table[name] = n
    else
      if symbol <= max_terminal_symbol then
        error(("symbol %q must be a nonterminal symbol"):format(name))
      end
    end
  end

  local check_table = {}

  for production in production_builders:each() do
    for name in production.body:each() do
      local symbol = symbol_table[name]
      if symbol == nil then
        error(("symbol %q not defined"):format(name))
      end
      check_table[symbol] = true
    end
  end

  for i = 2, max_terminal_symbol do
    if not check_table[i] then
      error(("terminal symbol %q not used"):format(symbol_names[i]))
    end
  end

  local start_symbol = symbol_table[start_name]
  if start_symbol == nil then
    error(("start symbol %q not defined"):format(start_name))
  end
  if start_symbol <= max_terminal_symbol then
    error(("start symbol %q must be a nonterminal symbol"):format(start_name))
  end

  local max_nonterminal_symbol = n

  local scanners = sequence()
  for scanner_builder in scanner_builders:each() do
    local scanner = sequence()
    for item in scanner_builder.items:each() do
      local item = clone(item)
      item.symbol = symbol_table[item.name]
      item.name = nil
      if item.action == "call" then
        local arguments = item.arguments
        local name = arguments[1]
        local id = scanner_table[name]
        if id == nil then
          error(("scanner %q not defined"):format(name))
        end
        arguments[1] = id
      end
      scanner:push(item)
    end
    scanners:push(scanner)
  end

  local symbol_precedences = {}
  for item in precedence_builder.items:each() do
    local name = item.name
    local symbol = symbol_table[name]
    if symbol ~= nil then
      if symbol > max_terminal_symbol then
        error(("symbol %q must be a terminal symbol"):format(name))
      end
      symbol_precedences[symbol] = {
        precedence = item.precedence;
        associativity = item.associativity;
      }
    end
  end

  local productions = sequence():push({
    head = max_terminal_symbol + 1;
    body = sequence():push(start_symbol);
  })

  local production_precedences = {}

  for production in production_builders:each() do
    local body = sequence()
    for name in production.body:each() do
      body:push(symbol_table[name])
    end
    productions:push({
      head = symbol_table[production.head];
      body = body;
    })
    local name = production.precedence
    if name ~= nil then
      local item = precedence_builder.table[name]
      if item == nil then
        error(("production precedence %q not defined"):format(name))
      end
      production_precedences[#productions] = {
        precedence = item.precedence;
        associativity = item.associativity;
      }
    end
  end

  self.symbol_names = symbol_names
  self.symbol_table = symbol_table
  self.scanner_names = scanner_names
  self.scanner_table = scanner_table

  local scanner = scanner(scanners)
  local grammar = grammar(productions, max_terminal_symbol, max_nonterminal_symbol, symbol_precedences, production_precedences)
  grammar.first_table = grammar:eliminate_left_recursion():first()
  local writer = writer(symbol_names, productions, max_terminal_symbol)
  return scanner, grammar, writer
end

class.metatable = {
  __index = class;
}

function class.metatable:__call(name)
  return production_builder(self.production_builders, name)
end

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), class.metatable)
  end;
})
