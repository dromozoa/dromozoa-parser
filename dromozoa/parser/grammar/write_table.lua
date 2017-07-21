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

return function (self, out, data)
  local symbol_names = self.symbol_names
  local max_terminal_symbol = self.max_terminal_symbol
  local max_nonterminal_symbol = self.max_nonterminal_symbol
  local max_state = data.max_state
  local table = data.table


  out:write([[
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
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
        <td colspan="]], max_nonterminal_symbol - max_terminal_symbol, [[">GOTO</td>
      </tr>
]])

  out:write('      <tr>\n')
  for i = 1, max_nonterminal_symbol do
    out:write('        <td>', symbol_names[i], '</td>\n') -- [TODO] escape
  end
  out:write('      </tr>\n')

  for i = 1, max_state do
    out:write([[
      <tr>
        <td>]], i, [[</td>
]])
    for j = 1, max_nonterminal_symbol do
      local action = table[i * max_nonterminal_symbol + j]
      out:write('        <td>')
      if action then
        if action <= max_state then
          if j <= max_terminal_symbol then
            out:write('s')
          end
          out:write(action)
        else
          local reduce = action - max_state
          if reduce == 1 then
            out:write("acc")
          else
            out:write("r", reduce)
          end
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
