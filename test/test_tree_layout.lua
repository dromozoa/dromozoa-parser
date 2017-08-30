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

local tree_layout = require "dromozoa.parser.tree_layout"

local nodes = {}
for i = 1, 23 do
  nodes[i] = { name = tostring(i) }
end

local links = {
  [1] = { 2, 13 };
  [2] = { 3, 12 };
  [3] = { 4, 11 };
  [4] = { 5, 6 };
  [6] = { 7, 8 };
  [8] = { 9, 10 };
  [13] = { 14, 15 };
  [15] = { 16, 17 };
  [17] = { 18, 19 };
  [18] = { 20, 21 };
  [20] = { 22, 23 };
}

for id, link in pairs(links) do
  local node = nodes[id]
  node[1] = nodes[link[1]]
  node[2] = nodes[link[2]]
end

tree_layout(nodes[1])
