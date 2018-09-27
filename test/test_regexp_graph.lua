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

local start_state = dfa.start_state
print(start_state)

local g, e_labels = to_graph(dfa)
local root = g:render {
  matrix = vecmath.matrix3(0, 100, 50, 50, 0, 25, 0, 0, 1);
  e_labels = e_labels;
}

local u_paths = root[1]
local u_texts = root[2]
local e_paths = root[3]
local e_texts = root[4]

for i = 1, #u_paths do
  local path = u_paths[i]
  local uid = path["data-uid"]
  if uid == start_state then
    local text = u_texts[i]
    path.class = "start_state"
    text.class = "start_state"
  end
end

local e_bg_texts = _"g" { class ="e_bg_texts" }
for i = 1, #e_texts do
  e_bg_texts[i] = e_texts[i]
end

local doc = dom.xml_document(_"svg" {
  version = "1.1";
  xmlns = "http://www.w3.org/2000/svg";
  width = root["data-width"];
  height = root["data-height"];
  _"defs" {
    _"marker" {
      id = "arrow";
      viewBox = "0 0 4 4";
      refX = 4;
      refY = 2;
      markerWidth = 8;
      markerHeight = 8;
      orient = "auto";
      _"path" {
        d = svg.path_data():M(0,0):L(4,2):L(0,4):Z();
      };
    };
  };
  u_paths;
  u_texts;
  e_paths;
  e_bg_texts;
  e_texts;
})
doc.stylesheets = {
  { href = "docs/automaton.css" }
}

local out = assert(io.open("test.svg", "w"))
doc:serialize(out)
out:write "\n"
out:close()
