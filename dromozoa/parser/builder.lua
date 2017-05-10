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
local precedence = require "dromozoa.parser.builder.precedence"
local production = require "dromozoa.parser.builder.production"
local scanner_builder = require "dromozoa.parser.scanner_builder"

local class = {}

function class.new()
  return {
    scanners = sequence():push(scanner_builder());
    precedence = precedence();
    productions = sequence();
  }
end

function class:scanner(name)
  local scanners = self.scanners
  if name == nil then
    return scanners[1]
  end
  local scanner = scanner_builder(name)
  scanners:push(scanner)
  return scanner
end

function class:lit(literal)
  return self:scanner():lit(literal)
end

function class:pat(pattern)
  return self:scanner():pat(pattern)
end

function class:left(name)
  return self.precedence:left(name)
end

function class:right(name)
  return self.precedence:right(name)
end

function class:nonassoc(name)
  return self.precedence:nonassoc(name)
end

function class:build(start_name)
  local scanners = self.scanners
  local precedence = self.precedence
  local productions = self.productions

  if start_name == nil then
    start_name = productions[1].head
  end

  local scanner_table = {}

  local n = 1
  local symbols = { "$" }
  local symbol_table = {}

  for i, scanner in ipairs(scanners) do
    local name = scanner.name
    if name ~= nil then
      scanner_table[name] = i
    end
    for rule in scanner:each() do
      local action = rule.action
      if action == nil or action[1] ~= "ignore" then
        local name = rule.name
        -- [TODO] do not check or check in this scanner
        if symbol_table[name] ~= nil then
          error(("symbol %q already defined"):format(name))
        end
        n = n + 1
        symbols[n] = name
        symbol_table[name] = n
      end
    end
  end

  local max_terminal_symbol = n

  for production in productions:each() do
    local head = production.head
    local symbol = symbol_table[head]
    if symbol == nil then
      n = n + 1
      symbols[n] = head
      symbol_table[head] = n
    else
      if symbol <= max_terminal_symbol then
        error(("head %q must be a nonterminal symbol"):format(head))
      end
    end
  end

  for production in productions:each() do
    for name in production.body:each() do
      if symbol_table[name] == nil then
        error(("symbol %q not defined"):format(name))
      end
    end
  end

  local start_symbol = symbol_table[start_name]
  if start_symbol == nil then
    error(("start symbol %q not defined"):format(start_name))
  end
  if start_symbol <= max_terminal_symbol then
    error(("start symbol %q must be a nonterminal symbol"):format(start_name))
  end

  n = n + 1
  symbols[n] = start_name .. "'"

  local max_nonterminal_symbol = n -- argumented_start_symbol

  local result_scanners = sequence()
  for scanner in scanners:each() do
    local result_scanner = sequence()
    for rule in scanner:each() do
      local name = rule.name
      local action = rule.action
      local result_action
      if action ~= nil then
        if action[1] == "call" then
          local name = action[2]
          local id = scanner_table[action[2]]
          if id == nil then
            error(("scanner %q not defined"):format(name))
          end
          result_action = { "call", id }
        else
          result_action = { action[1] }
        end
      end
      result_scanner:push({
        symbol = symbol_table[name];
        match = rule.match;
        action = result_action;
      })
    end
    result_scanners:push(result_scanner)
  end

  local symbol_precedences = {}
  for name, precedence in pairs(precedence.map) do
    local symbol = symbol_table[name]
    if symbol ~= nil then
      if symbol > max_terminal_symbol then
        error(("symbol %q must be a terminal symbol"):format(name))
      end
      symbol_precedences[symbol] = {
        precedence = precedence.precedence;
        is_left = precedence.associativity == "left";
      }
    end
  end

  local result_productions = sequence():push({
    head = max_nonterminal_symbol;
    body = sequence():push(start_symbol);
  })

  local production_precedences = {}

  for production in productions:each() do
    local body = sequence()
    for name in production.body:each() do
      body:push(symbol_table[name])
    end
    result_productions:push({
      head = symbol_table[production.head];
      body = body;
    })
    local name = production.precedence
    if name ~= nil then
      local precedence = precedence.map[name]
      if precedence == nil then
        error(("production precedence %q not defined"):format(name))
      end
      production_precedences[#result_productions] = {
        precedence = precedence.precedence;
        is_left = precedence.associativity == "left";
      }
    end
  end

  -- [TODO] check unused terminal symbol

  return {
    symbols = symbols;
    symbol_table = symbol_table;
    symbol_precedences = symbol_precedences;
    production_precedences = production_precedences;
    scanners = result_scanners;
    productions = result_productions;
    max_terminal_symbol = max_terminal_symbol;
    max_nonterminal_symbol = max_nonterminal_symbol;
  }
end

class.metatable = {
  __index = class;
}

function class.metatable:__call(name)
  return production(self.productions, name)
end

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), class.metatable)
  end;
})
