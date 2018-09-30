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

local char_table = {
  ["\a"] = [[\a]];
  ["\b"] = [[\b]];
  ["\f"] = [[\f]];
  ["\n"] = [[\n]];
  ["\r"] = [[\r]];
  ["\t"] = [[\t]];
  ["\v"] = [[\v]];
  ["\\"] = [[\\]]; -- 92
  ["\""] = [[\"]]; -- 34
  ["\'"] = [[\']]; -- 39
}

for byte = 0x00, 0xFF do
  local char = string.char(byte)
  if not char_table[char] then
    char_table[char] = ([[\%03d]]):format(byte)
  end
end

return function (s)
  return "\"" .. s:gsub("[%z\1-\31\34\92\127-\255]", char_table) .. "\""
end
