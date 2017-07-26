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

local TO = string.char(0xE2, 0x86, 0x92) -- U+2192 RIGHWARDS ARROW
local DOT = string.char(0xC2, 0xB7) -- U+00B7 MIDDLE DOT

return function (self, out, set_of_items, transitions)
  local symbol_names = self.symbol_names
  local productions = self.productions
  out:write('digraph {\n  graph [rankdir=LR];\n')
  for i = 1, #set_of_items do
    local items = set_of_items[i]
    local accept
    out:write('  ', i, ' [shape=none,width=0,height=0,margin=0,label=<\n    <table border="1" cellborder="0" cellspacing="0">\n      <tr><td>I<font point-size="10">', i - 1, '</font></td></tr>\n')
    for j = 1, #items do
      local item = items[j]
      local id = item.id
      local production = productions[id]
      local body = production.body
      local dot = item.dot
      local la = item.la
      out:write('      <tr><td align="left"')
      if id == 1 and dot ~= 1 then
        accept = true
      elseif id ~= 1 and dot == 1 then
        out:write(' bgcolor="gray"')
      end
      out:write('>', escape_html(symbol_names[production.head]), ' ', TO)
      for k = 1, #body do
        if k == dot then
          out:write(' ', DOT)
        end
        out:write(' ', escape_html(symbol_names[body[k]]))
      end
      if dot == #body + 1 then
        out:write(' ', DOT)
      end
      if la then
        out:write(', ', escape_html(symbol_names[la]))
      end
      out:write('</td></tr>\n')
    end
    out:write('    </table>\n  >];\n')
    if accept then
      out:write('  0 [shape=plaintext,label=<accept>];\n')
      out:write('  ', i, ' -> 0 [label=<$>];\n')
    end
  end
  for from, transition in pairs(transitions) do
    for symbol, to in pairs(transition) do
      out:write('  ', from, ' -> ', to, ' [label=<', escape_html(symbol_names[symbol]), '>];\n')
    end
  end
  out:write('}\n')
  return out
end
