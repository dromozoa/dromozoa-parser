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
local write_html = require "dromozoa.parser.write_html"

local nodes = {}
for i = 1, 23 do
  nodes[i] = { id = tostring(i) }
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

local svg_nodes = { "g"; class = "nodes" }
local svg_edges = { "g"; class = "edges" }

tree_layout(nodes[1])

local width = 640
local height = 640
for i = 1, #nodes do
  local u = nodes[i]
  u.x = u.x * 50 + width * 0.5
  u.y = u.y * 50 + 50
  svg_nodes[#svg_nodes + 1] = { "g";
    transform = "translate(" .. u.x..","..u.y .. ")";
    { "text"; u.id };
  }
end
for i = 1, #nodes do
  local u = nodes[i]
  local ux = u.x
  local uy = u.y
  for j = 1, #u do
    local v = u[j]
    local vx = v.x
    local vy = v.y
    local mx = (ux + vx) * 0.5
    local my = (uy + vy) * 0.5
    svg_edges[#svg_edges + 1] = { "g";
      { "path"; d = "M" .. ux..",".. uy .. "C" .. mx..","..my .. "," .. mx..","..my .. "," .. vx..","..vy };
    }
  end
end

local style = [[
.edges path {
  fill: none;
  stroke: #000;
}
]]

write_html(io.stdout, { "html";
  { "head";
    { "meta"; charset = "UTF-8" };
    { "style"; style };
  };
  { "body";
    { "svg"; width = width; height = height;
      { "g";
        svg_nodes;
        svg_edges;
      };
    };
  };
})
io.write("\n")
