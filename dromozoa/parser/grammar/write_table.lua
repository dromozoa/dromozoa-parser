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

local escape_html = require "dromozoa.parser.escape_html"

return function (self, out, data)
  local symbol_names = self.symbol_names
  local max_terminal_symbol = self.max_terminal_symbol
  local min_nonterminal_symbol = self.min_nonterminal_symbol
  local max_nonterminal_symbol = self.max_nonterminal_symbol
  local max_state = data.max_state
  local table = data.table
  local actions = data.actions
  local gotos = data.gotos

  out:write([[
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>table</title>
    <style>
      table {
        border-collapse: collapse;
      }
      td {
        border: 1px solid #ccc;
        text-align: center;
      }
    </style>
  </head>
  <body>
    <table>
]])

  out:write([[
      <tr>
        <td rowspan="2">STATE</td>
        <td colspan="]], max_terminal_symbol, [[">ACTION</td>
        <td colspan="]], max_nonterminal_symbol - min_nonterminal_symbol, [[">GOTO</td>
      </tr>
]])

  out:write('      <tr>\n')
  for i = 2, min_nonterminal_symbol do
    if i == min_nonterminal_symbol then
      i = 1
    end
    out:write('        <td>', escape_html(symbol_names[i]), '</td>\n')
  end
  for i = min_nonterminal_symbol + 1, max_nonterminal_symbol do
    out:write('        <td>', escape_html(symbol_names[i]), '</td>\n')
  end
  out:write('      </tr>\n')

  for i = 1, max_state do
    out:write([[
      <tr>
        <td>]], i - 1, [[</td>
]])
    for j = 2, min_nonterminal_symbol do
      if j == min_nonterminal_symbol then
        j = 1
      end
      out:write('        <td>')
      local t = actions[i]
      if t then
        local action = t[j]
        if action then
          if action <= max_state then
            out:write('s', action - 1)
          else
            local reduce = action - max_state
            if reduce == 1 then
              out:write("acc")
            else
              out:write("r", reduce - 1)
            end
          end
        end
      end
      out:write('</td>\n')
    end
    for j = min_nonterminal_symbol + 1, max_nonterminal_symbol do
      out:write('        <td>')
      local t = gotos[i]
      if t then
        local action = t[j - max_terminal_symbol]
        if action then
          out:write(action - 1)
        end
      end
      out:write('</td>\n')
    end
    out:write('      </tr>\n')
  end

  out:write([[
    </table>
  </body>
</html>
]])
  return out
end
