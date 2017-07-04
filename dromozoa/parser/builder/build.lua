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

local lexer = require "dromozoa.parser.lexer"
local regexp = require "dromozoa.parser.regexp"

return function (self, start_name)
  local lexers = self.lexers

  local n = 1
  local symbol_names = { "$" }
  local symbol_table = {}

  local lexer_names = {}
  local lexer_table = {}

  for i = 1, #lexers do
    local lexer = lexers[i]
    local name = lexer.name
    local items = lexer.items
    if name then
      lexer_names[i] = name
      lexer_table[name] = i
    end
    local accept_table = {}
    for j = 1, #items do
      local item = items[j]
      if not item.skip then
        local name = item.name
        if not name then
          error(("lexer %d pattern %d is unnamed"):format(i, j))
        end
        local symbol = symbol_table[name]
        if not symbol then
          n = n + 1
          symbol = n
          symbol_names[n] = name
          symbol_table[name] = n
        end
        accept_table[j] = symbol
      end
    end
    lexer.accept_table = accept_table
    local automaton = regexp(items[1].pattern, 1):nfa_to_dfa():minimize()
    for j = 2, #items do
      automaton:union(regexp(items[j].pattern, j):nfa_to_dfa():minimize())
    end
    lexer.automaton = automaton:nfa_to_dfa():minimize()
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
            error(("lexer %q not defined at lexer %d pattern %d action %d"):format(name, i, j, k))
          end
          action[2] = lexer
        end
      end
    end
  end

  local max_terminal_symbol = n

  self.symbol_names = symbol_names
  self.symbol_table = symbol_table
  self.max_terminal_symbol = max_terminal_symbol
  self.lexer_names = lexer_names
  self.lexer_table = lexer_table

  return lexer(lexers)
end
