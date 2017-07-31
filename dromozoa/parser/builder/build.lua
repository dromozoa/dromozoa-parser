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

local grammar = require "dromozoa.parser.grammar"
local lexer = require "dromozoa.parser.lexer"
local regexp = require "dromozoa.parser.regexp"

return function (self, start_name)
  local lexers = self.lexers
  local lexer_names = {}
  local lexer_table = {}

  local n = 1
  local symbol_names = { "$" }
  local symbol_table = {}

  for i = 1, #lexers do
    local lexer = lexers[i]
    local name = lexer.name
    local items = lexer.items
    if name then
      lexer_names[i] = name
      lexer_table[name] = i
    end
    local m = #items
    local accept_to_symbol = {}
    for j = 1, m do
      local item = items[j]
      if not item.skip then
        local name = item.name
        if not name then
          error(("pattern unnamed at lexer %d pattern %d"):format(i, j))
        end
        local symbol = symbol_table[name]
        if not symbol then
          n = n + 1
          symbol = n
          symbol_names[n] = name
          symbol_table[name] = n
        end
        accept_to_symbol[j] = symbol
      end
    end
    lexer.accept_to_symbol = accept_to_symbol
    if lexer.type == "regexp_lexer" then
      if m == 1 then
        lexer.automaton = regexp(items[1].pattern, 1):nfa_to_dfa():minimize()
      else
        local automaton = regexp(items[1].pattern, 1):nfa_to_dfa():minimize()
        for j = 2, m do
          automaton:union(regexp(items[j].pattern, j):nfa_to_dfa():minimize())
        end
        lexer.automaton = automaton:nfa_to_dfa():minimize()
      end
    else
      if m ~= 2 or items[1].condition ~= 1 or items[2].condition ~= 2 then
        error(("invalid when/otherwise at lexer %d"):format(i))
      end
    end
  end

  for i = 1, #lexers do
    local items = lexers[i].items
    for j = 1, #items do
      local actions = items[j].actions
      for k = 1, #actions do
        local action = actions[k]
        if action[1] == 4 then -- call
          local name = action[2]
          local lexer = lexer_table[name]
          if not lexer then
            error(("lexer %s not defined at lexer %d pattern %d action %d"):format(name, i, j, k))
          end
          action[2] = lexer
        end
      end
    end
  end

  local max_terminal_symbol = n

  self.lexer_names = lexer_names
  self.lexer_table = lexer_table
  self.symbol_names = symbol_names
  self.symbol_table = symbol_table
  self.max_terminal_symbol = max_terminal_symbol

  local productions = self.productions
  local m = #productions
  if m == 1 then
    return lexer(lexers)
  else
    local precedences = self.precedences

    -- argumented start symbol
    if not start_name then
      start_name = productions[2].head
    end
    n = n + 1
    symbol_names[n] = start_name .. "'"

    for i = 2, m do
      local production = productions[i]
      local name = production.head
      local symbol = symbol_table[name]
      if symbol then
        if symbol <= max_terminal_symbol then
          error(("symbol %s must be a nonterminal symbol at production %d head"):format(name, i))
        end
      else
        n = n + 1
        symbol_names[n] = name
        symbol_table[name] = n
      end
    end

    local check_table = {}
    for i = 2, m do
      local body = productions[i].body
      for j = 1, #body do
        local name = body[j]
        local symbol = symbol_table[name]
        if not symbol then
          error(("symbol %s not defined at production %d body %d"):format(name, i, j))
        end
        check_table[symbol] = true
      end
    end
    for i = 2, max_terminal_symbol do
      if not check_table[i] then
        error(("terminal symbol %s not used"):format(symbol_names[i]))
      end
    end

    local start_symbol = symbol_table[start_name]
    if not start_symbol then
      error(("start symbol %s not defined"):format(start_name))
    end
    if start_symbol <= max_terminal_symbol then
      error(("start symbol %s must be a nonterminal symbol"):format(start_name))
    end

    local symbol_precedences = {}
    local production_precedences = {}
    local precedence_table = {}

    for i = 1, #precedences do
      local precedence = precedences[i]
      local associativity = precedence.associativity
      local items = precedence.items
      for j = 1, #items do
        local name = items[j]
        local symbol = symbol_table[name]
        if symbol then
          if symbol > max_terminal_symbol then
            error(("symbol %s must be a terminal symbol at precedence %d symbol %d"):format(name, i, j))
          end
          if symbol_precedences[symbol] then
            error(("precedence already defined at precedence %d symbol %d"):format(i, j))
          end
          symbol_precedences[symbol] = {
            precedence = i;
            associativity = associativity;
          }
        else
          if precedence_table[name] then
            error(("precedence already defined at precedence %d symbol %d"):format(i, j))
          end
          precedence_table[name] = {
            precedence = i;
            associativity = associativity;
          }
        end
      end
    end

    productions[1] = {
      head = max_terminal_symbol + 1;
      body = { start_symbol };
    }

    for i = 2, m do
      local production = productions[i]
      production.head = symbol_table[production.head]
      local body = production.body
      for j = 1, #body do
        body[j] = symbol_table[body[j]]
      end
      local name = production.precedence
      if name then
        local precedence = precedence_table[name]
        if not precedence then
          error(("production precedence %s not defined at production %d"):format(name, i))
        end
        production_precedences[i] = precedence
      end
    end

    self.max_nonterminal_symbol = n
    self.symbol_precedences = symbol_precedences
    self.production_precedences = production_precedences

    local grammar = grammar(self)
    grammar.first_table = grammar:eliminate_left_recursion():first()
    return lexer(lexers), grammar
  end
end
