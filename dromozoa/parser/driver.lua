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
  local lexer = self.lexer
  local parser = self.parser
  parser.file = file
  parser.source = s
  local position = 1
  while true do
    local symbol, p, i, j, rs, ri, rj = lexer(s, position, file)
    if not symbol then
      return nil, p
    end
    local result, message = parser(symbol, p, i, j - 1, rs, ri, rj)
    if not result then
      return nil, message
    end
    if symbol == 1 then
      return result
    end
    position = j
  end
end

return setmetatable(class, {
  __call = function (_, lexer, parser)
    return setmetatable({ lexer = lexer, parser = parser }, metatable)
  end;
})
