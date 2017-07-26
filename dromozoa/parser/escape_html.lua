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

local char_table = {}
for byte = 0, 127 do
  char_table[string.char(byte)] = ("&#x%x;"):format(byte)
end
char_table[string.char(0x26)] = "&amp;"
char_table[string.char(0x3c)] = "&lt;"
char_table[string.char(0x3e)] = "&gt;"
char_table[string.char(0x22)] = "&quot;"
char_table[string.char(0x27)] = "&apos;"

local escape_pattern = "[%z\1-\8\11\12\14-\31\127&<>\"']"

return function (s)
  return (s:gsub(escape_pattern, char_table))
end
