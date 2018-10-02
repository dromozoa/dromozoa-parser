-- Copyright (C) 2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local element = require "dromozoa.dom.element"
local xml_document = require "dromozoa.dom.xml_document"
local matrix3 = require "dromozoa.vecmath.matrix3"
local path_data = require "dromozoa.svg.path_data"
local graph = require "dromozoa.graph"

local _ = element

local style = _"style" { [[
@import url('https://fonts.googleapis.com/css?family=Roboto+Mono');

text {
  font-family: 'Roboto Mono', monospace;
  font-size: 16;
  text-anchor: middle;
  dominant-baseline: central;
}

.u_paths {
  fill: none;
  stroke: #000;
}

.u_texts {
  fill: #000;
  stroke: none;
}

.e_paths {
  fill: none;
  stroke: #000;
  marker-end: url(#arrow);
}

.e_texts.z1 {
  fill: #FFF;
  stroke: #FFF;
  stroke-width: 4;
}

.e_texts.z2 {
  fill: #000;
  stroke: none;
}
]] }

local marker = _"marker" {
  id = "arrow";
  viewBox = "0 0 4 4";
  refX = 4;
  refY = 2;
  markerWidth = 8;
  markerHeight = 8;
  orient = "auto";
  _"path" {
    d = path_data():M(0,0):L(4,2):L(0,4):Z();
  };
}

return function (this, out, set_of_items, transitions)
  local symbol_names = this.symbol_names

  local that = graph()
  local u_labels = {}
  local e_labels = {}

  local accept
  local n = #set_of_items
  for i = 1, n do
    that:add_vertex()
    u_labels[i] = "I" .. i
    local items = set_of_items[i]
    for j = 1, #items do
      local item = items[j]
      if item.id == 1 and item.dot ~= 1 then
        accept = i
        break
      end
    end
  end
  n = n + 1
  that:add_vertex()
  u_labels[n] = "accept"
  e_labels[that:add_edge(accept, n)] = "$"

  for from, transition in pairs(transitions) do
    for symbol, to in pairs(transition) do
      e_labels[that:add_edge(from, to)] = symbol_names[symbol]
    end
  end

  local root = that:render {
    matrix = matrix3(0, 100, 50, 50, 0, 25, 0, 0, 1);
    u_labels = u_labels;
    e_labels = e_labels;
  }

  local e_texts = root[4]
  e_texts.class = nil
  e_texts.id = "e_texts"
  local defs = _"defs" { style, marker, e_texts }

  local doc = xml_document(_"svg" {
    version = "1.1";
    xmlns = "http://www.w3.org/2000/svg";
    ["xmlns:xlink"] = "http://www.w3.org/1999/xlink";
    width = root["data-width"];
    height = root["data-height"];
    defs;
    root[1];
    root[2];
    root[3];
    _"use" {
      class = "e_texts z1";
      ["xlink:href"] = "#e_texts";
    };
    _"use" {
      class = "e_texts z2";
      ["xlink:href"] = "#e_texts";
    };
  })

  doc:serialize(out)
  out:write "\n"
  return out
end
