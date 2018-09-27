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

local builder = require "dromozoa.parser.builder"
local regexp = require "dromozoa.parser.regexp"
local to_graph = require "dromozoa.parser.regexp.to_graph"

local layout = require "dromozoa.graph.layout"
local render = require "dromozoa.graph.render"
local subdivide_special_edges = require "dromozoa.graph.subdivide_special_edges"
local vecmath = require "dromozoa.vecmath"

local dom = require "dromozoa.dom"
local svg = require "dromozoa.svg"

local P = builder.pattern
local R = builder.range
local S = builder.set

local _ = dom.element
local path_data = svg.path_data

local p = P"/*" * (P(1)^"*" - P(1)^"*" * P"*/" * P(1)^"*") * P"*/"
local nfa = regexp(p)
local dfa = nfa:nfa_to_dfa():minimize()

local g, e_labels = to_graph(dfa)
e_labels = e_labels or {}
local last_uid = g.u.last
local last_eid = g.e.last
local revered_eids = subdivide_special_edges(g, e_labels)
local x, y, paths = layout(g, last_uid, last_eid, revered_eids)

local matrix = vecmath.matrix3(0, 100, 50, 100, 0, 50, 0, 0, 1)
local node = render(g, last_uid, last_eid, x, y, paths, {
  matrix = matrix;
  e_labels = e_labels;
  max_text_length = 72;
  curve_parameter = 1;
})

local size = matrix:transform(vecmath.vector2(x.max + 1, y.max + 1))

local doc = dom.xml_document(_"svg" {
  version = "1.1";
  xmlns = "http://www.w3.org/2000/svg";
  width = size.x;
  height = size.y;
  _"defs" {
    _"style" {
      type = "text/css";
      "@import url('https://dromozoa.github.io/dromozoa-graph/sample.css');";
    };
    _"marker" {
      id = "arrow";
      viewBox = "0 0 4 4";
      refX = 4;
      refY = 2;
      markerWidth = 8;
      markerHeight = 8;
      orient = "auto";
      _"path" {
        d = svg.path_data():M(0,0):L(0,4):L(4,2):Z();
      };
    };
  };
  node;
})

local out = assert(io.open("test.svg", "w"))
doc:serialize(out)
out:write "\n"
out:close()
