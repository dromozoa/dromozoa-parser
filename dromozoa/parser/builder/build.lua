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

return function (data, start_name)
  local lexers = data.lexers

  local n = 1
  local symbol_names = { "$" }
  local symbol_table = {}
  local lexer_names = {}
  local lexer_table = {}

  for i = 1, #lexers do
    local lexer = lexers[i]
    local name = lexer.name
    local items = lexer.items
    if name ~= nil then
      lexer_names[i] = name
      lexer_table[name] = i
    end
    local check_table = {}
    for j = 1, #items do
      local item = items[j]
      local action = item.action
      if action == nil or action[1] ~= nil then
        local name = item.name
        if name == nil then
          error(("lexer %d pattern %d is not named"):format(i, j))
        end
        if check_table[name] then
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

  return {
    symbol_names = symbol_names;
    symbol_table = symbol_table;
    max_terminal_symbol = max_terminal_symbol;
  }
end
