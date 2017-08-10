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

local class = {}
local metatable = {
  __index = class;
}
class.metatable = metatable

function metatable:__call(s, file)
  local terminal_nodes, message = self.lexer(s, file)
  if not terminal_nodes then
    return nil, message
  end
  local accepted_node, message = self.parser(terminal_nodes, s, file)
  if not accepted_node then
    return nil, message
  end
  return accepted_node
end

return setmetatable(class, {
  __call = function (_, lexer, parser)
    return setmetatable({ lexer = lexer, parser = parser }, metatable)
  end;
})
