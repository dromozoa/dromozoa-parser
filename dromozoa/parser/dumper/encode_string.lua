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
for byte = 0, 255 do
  char_table[string.char(byte)] = ([[\%03d]]):format(byte)
end
char_table["\a"] = [[\a]]
char_table["\b"] = [[\b]]
char_table["\f"] = [[\f]]
char_table["\n"] = [[\n]]
char_table["\r"] = [[\r]]
char_table["\t"] = [[\t]]
char_table["\v"] = [[\v]]
char_table["\\"] = [[\\]] -- 92
char_table["\""] = [[\"]] -- 34
char_table["\'"] = [[\']] -- 39

local pattern = "[%z\1-\31\34\39\92\127-\255]"

return function (s)
  return [["]] .. s:gsub(pattern, char_table) .. [["]]
end
