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

return function (self, out, tree)
  local symbol_names = self.symbol_names

  out:write('graph {\n  graph [rankdir=TB];\n')

  local stack = { tree }
  local id_table = { [tree] = 1 }
  local id = 1

  while true do
    local n = #stack
    local u = stack[n]
    if u then stack[n] = nil
      local uid = id_table[u]
      local name = symbol_names[u[0]]
      local value = u.value
      if value == name then
        value = nil
      end
      out:write('  ', uid, ' [shape=none,width=0,height=0,margin=0,label=<\n    <table border="0" cellborder="1" cellspacing="0">\n      <tr><td>', escape_html(name), '</td></tr>\n')
      if value then
        out:write('      <tr><td balign="left">', (escape_html(value):gsub("\n", "<br/>")), '</td></tr>\n')
      end
      out:write('    </table>\n  >];\n')
      local m = u.n
      for i = 1, m do
        id = id + 1
        id_table[u[i]] = id
        out:write('  ', uid, ' -- ', id, ';\n')
      end
      for i = m, 1, -1 do
        stack[#stack + 1] = u[i]
      end
    else
      break
    end
  end

  out:write('}\n')

  return out
end
