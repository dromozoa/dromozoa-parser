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

return function (message, s, position, file)
  if not file then
    file = "<unknown>"
  end
  local n = 1
  local i = 1
  while true do
    local j = s:find("\n", i, true)
    if j then
      if position <= j then
        return file .. ":" .. n .. ":" .. position - i + 1 .. ": " .. message
      end
      n = n + 1
      i = j + 1
    else
      if position <= #s then
        return file .. ":" .. n .. ":" .. position - i + 1 .. ": " .. message
      end
      return file .. ":eof: " .. message
    end
  end
end
