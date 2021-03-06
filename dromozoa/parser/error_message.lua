-- Copyright (C) 2017,2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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
  local j, m, eol = s:find "([\n\r][\n\r]?)"
  if j then
    if eol == "\n\n" then
      eol = "\n"
      m = 1
    elseif eol == "\r\r" then
      eol = "\r"
      m = 1
    else
      m = m - j + 1
    end
    repeat
      if position <= j then
        return file .. ":" .. n .. ":" .. position - i + 1 .. ": " .. message
      end
      n = n + 1
      i = j + m
      j = s:find(eol, i, true)
    until not j
  end
  if position <= #s then
    return file .. ":" .. n .. ":" .. position - i + 1 .. ": " .. message
  else
    return file .. ":eof: " .. message
  end
end
