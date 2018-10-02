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
local to_graph = require "dromozoa.parser.regexp.to_graph"

local _ = element

local style = _"style" { [[
@import url('https://fonts.googleapis.com/css?family=Roboto+Mono');

text {
  font-family: 'Roboto Mono', monospace;
  font-size: 16;
  text-anchor: middle;
  dominant-baseline: central;
}

.u_paths.z1 {
  fill: none;
  stroke: #000;
}

.u_paths.z1 .start_state {
  fill: #000;
}

.u_paths.z1 .accept_state {
  stroke-width: 3;
}

.u_paths.z2 {
  fill: none;
  stroke: #FFF;
  stroke-width: 1;
}

.u_texts {
  fill: #000;
  stroke: none;
}

.u_texts .start_state {
  fill: #FFF;
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

return function (this, out)
  local start_state = this.start_state
  local accept_states = this.accept_states

  local g, u_labels, e_labels = to_graph(this)
  local root = g:render {
    matrix = matrix3(0, 100, 50, 50, 0, 25, 0, 0, 1);
    u_labels = u_labels;
    e_labels = e_labels;
    shape = "ellipse";
  }

  local u_paths1 = root[1]
  local u_paths2 = _"g" { class = "u_paths z2" }
  local u_texts = root[2]
  local e_texts = root[4]
  u_paths1.class = "u_paths z1"
  e_texts.class = nil
  e_texts.id = "e_texts"
  local defs = _"defs" { style, marker, e_texts }

  for i = 1, #u_paths1 do
    local path = u_paths1[i]
    local u = path["data-uid"]
    if accept_states[u] then
      local id = "u_path" .. u
      path.id = id
      defs[#defs + 1] = path

      local path = _"use" { ["xlink:href"] = "#" .. id }
      u_paths1[i] = path
      u_paths2[#u_paths2 + 1] = path

      if u == start_state then
        path.class = "start_state accept_state"
        u_texts[i].class = "start_state accept_state"
      else
        path.class = "accept_state"
        u_texts[i].class = "accept_state"
      end
    elseif u == start_state then
      path.class = "start_state"
      u_texts[i].class = "start_state"
    end
  end

  local doc = xml_document(_"svg" {
    version = "1.1";
    xmlns = "http://www.w3.org/2000/svg";
    ["xmlns:xlink"] = "http://www.w3.org/1999/xlink";
    width = root["data-width"];
    height = root["data-height"];
    defs;
    u_paths1;
    u_paths2;
    u_texts;
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
