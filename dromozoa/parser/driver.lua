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
  local position = 1
  while true do
    local symbol, p, i, j, rs, ri, rj = assert(lexer(s, position))
    if symbol == 1 then
      return assert(parser(symbol, s, file, p, i, j - 1, rs, ri, rj))
    else
      assert(parser(symbol, s, file, p, i, j - 1, rs, ri, rj))
    end
    position = j
  end
end

return setmetatable(class, {
  __call = function (_, lexer, parser)
    return setmetatable({ lexer = lexer, parser = parser }, metatable)
  end;
})
