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

local dumper = require "dromozoa.parser.dumper"
local escape_html = require "dromozoa.parser.escape_html"
local lua53_lexer = require "dromozoa.parser.lexers.lua53_lexer"
local lua53_parser = require "dromozoa.parser.parsers.lua53_parser"

local keys = dumper.keys

local function write_html(out, node)
  local number_keys, string_keys = keys(node)
  local name = assert(node[1])
  out:write("<", name)
  for i = 1, #string_keys do
    local key = string_keys[i]
    out:write(" ", escape_html(key), "=\"", escape_html(tostring(node[key])), "\"")
  end
  local n = #number_keys
  if name == "script" or name == "style" then
    out:write(">")
    local value = table.concat(node, "", 2, number_keys[n])
    if value:find("[<&]") then
      assert(not value:find("%]%]>"))
      if name == "script" then
        out:write("//<![CDATA[\n", value, "//]]>")
      else
        out:write("/*<![CDATA[*/\n", value, "/*]]>*/")
      end
    else
      out:write(value)
    end
    out:write("</", name, ">")
  else
    out:write(">")
    for i = 1, #number_keys do
      local key = number_keys[i]
      if key ~= 1 then
        local value = node[key]
        if type(value) == "table" then
          write_html(out, value)
        else
          out:write(escape_html(tostring(value)))
        end
      end
    end
    out:write("</", name, ">")
  end
end

local file = ...
local source

if file then
  local handle = assert(io.open(file))
  source = handle:read("*a")
  handle:close()
else
  source = io.read("*a")
end

local lexer = lua53_lexer()
local parser = lua53_parser()

local symbol_names = parser.symbol_names
local max_terminal_symbol = parser.max_terminal_symbol
local terminal_nodes = assert(lexer(source, file))
local root = assert(parser(terminal_nodes, source, file))

local id = 0
local nodes = {}
local dfs_events = {}
local dfs_nodes = {}

local stack1 = { root }
local stack2 = {}
while true do
  local n1 = #stack1
  local n2 = #stack2
  local u = stack1[n1]
  if not u then
    break
  end
  if u == stack2[n2] then
    stack1[n1] = nil
    stack2[n2] = nil
    local m = #dfs_events + 1
    dfs_events[m] = 2 -- finish
    dfs_nodes[m] = u

    local parent = u.parent
    if parent then
      local parent_html = parent.html
      local symbol = u[0]
      if symbol > max_terminal_symbol then
        parent_html[#parent_html + 1] = u.html
      else
        local p = u.p
        local i = u.i
        local j = u.j
        if p < i then
          parent_html[#parent_html + 1] = { "span";
            class = "color-skip";
            source:sub(p, i - 1);
          }
        end
        parent_html[#parent_html + 1] = { "span";
          id = "_" .. u.id;
          ["data-symbol"] = symbol;
          ["data-symbol-name"] = symbol_names[symbol];
          ["data-terminal-symbol"] = true;
          class = u.color;
          source:sub(i, j);
        }
      end
    end
  else
    id = id + 1
    u.id = id
    nodes[id] = u
    local m = #dfs_events + 1
    dfs_events[m] = 1 -- discover
    dfs_nodes[m] = u

    local symbol = u[0]
    if symbol > max_terminal_symbol then
      u.html = { "span",
        id = "_" .. id;
        ["data-symbol"] = symbol;
        ["data-symbol-name"] = symbol_names[symbol];
      }
    end

    local n = #u
    for i = 1, n do
      local v = u[i]
      v.parent = u
    end
    for i = n, 1, -1 do
      local v = u[i]
      stack1[#stack1 + 1] = v
    end
    stack2[n2 + 1] = u
  end
end

local root_html = root.html
local node = terminal_nodes[#terminal_nodes]
local p = node.p
local i = node.i
if p < i then
  root_html[#root_html + 1] = { "span";
    class = "color-skip";
    source:sub(p, i - 1);
  }
end

local line_number
if source:find("\n$") then
  line_number = 0
else
  line_number = 1
end
for _ in source:gmatch("\n") do
  line_number = line_number + 1
end

local number_width_rem = math.ceil(math.log(line_number, 10)) * 0.5
local number_html = { "div"; class="number" }
for i = 1, line_number do
  number_html[#number_html + 1] = { "span";
    id = "L" .. i;
    class = "color-number";
    ["data-number"] = i;
    i;
    "\n";
  }
end

local panel_width_rem = 40
local panel_html = { "div"; class="panel";
  { "div"; class = "tree-head";
    { "span"; class = "icon fa fa-minus-square-o" };
    { "span"; "Tree" };
  };
  { "div"; class = "tree" };
}

-- https://github.com/tbastos/vim-lua
-- https://github.com/reedes/vim-colors-pencil
local style = [[
@font-face {
  font-family: 'Noto Sans Mono CJK JP';
  font-style: normal;
  font-weight: 400;
  src: url('https://dromozoa.s3.amazonaws.com/mirror/NotoSansCJKjp-2017-04-03/NotoSansMonoCJKjp-Regular.otf') format('opentype');
}

@font-face {
  font-family: 'Noto Sans Mono CJK JP';
  font-style: normal;
  font-weight: 700;
  src: url('https://dromozoa.s3.amazonaws.com/mirror/NotoSansCJKjp-2017-04-03/NotoSansMonoCJKjp-Bold.otf') format('opentype');
}

body {
  margin: 0;
  font-family: 'Noto Sans Mono CJK JP', monospace;
  white-space: pre;
  font-weight: 400;
}

.body {
  position: relative;
}

.number {
  position: absolute;
  top: 0;
  left: 0.5rem;
  text-align: right;
}

.code {
  position: absolute;
  top: 0;
  left: ]] .. number_width_rem + 1.5 .. [[rem;
}

.panel {
  position: fixed;
  top: 0;
  right: 0;
  width: ]] .. panel_width_rem .. [[rem;
  background-color: rgba(241, 241, 241, 0.5); /* white */
}

.tree {
  height: 30rem;
}

.tree-head {
  background-color: rgba(198, 198, 198, 0.5); /* lighter_gray */
}

.icon {
  width: 1.5rem;
  text-align: center;
}

.color-number {
  color: #C6C6C6; /* ligher_gray */
}

.color-skip {
  color: #B2B2B2; /* light_gray */
}

.color-constant {
  color: #20A5BA; /* dark_cyan */
}

.color-operator,
.color-statement {
  color: #10A778; /* dark_green */
}

.color-structure,
[data-symbol-name='funcbody'] > [data-symbol-name='end'] {
  color: #C30771; /* dark_red */
}

.color-selection {
  background-color: #B6D6FD;
}
]]

local script = [[
(function (root) {
  var $ = root.jQuery;
  var d3 = root.d3;
  var panel_width_rem = ]] .. panel_width_rem .. [[;

  $(function () {
    var $tree = $(".tree");
    var tree_width = $tree.width();
    var tree_height = $tree.height();
    var rem = tree_width / panel_width_rem;

    var transition_duration = 500;
    var node_width = 160;
    var node_height = 32;

    var initial_zoom_x = tree_width * 0.5;
    var initial_zoom_y = tree_height * 0.5;
    var initial_zoom_scale = 1;
    var initial_transform = d3.zoomIdentity
      .translate(initial_zoom_x, initial_zoom_y)
      .scale(initial_zoom_scale);

    var zoom = d3.zoom();
    var zoom_x = 0;
    var zoom_y = 0;
    var zoom_scale = 1;

    var viewport_group;
    var view_group;
    var model_group;

    var color_fill = "#F1F1F1"; /* white */
    var color_focused = "#F3E430"; /* yellow */
    var color_stroke = "#000";

    $("[data-terminal-symbol]").on("click", function () {
      var node_group = $(this).data("node_group");
      var d = node_group.datum();
      var zx = tree_width * 0.5 - d.data.tx * zoom_scale;
      var zy = tree_height * 0.5 - d.data.ty * zoom_scale;
      var transform = d3.zoomIdentity
        .translate(zx, zy)
        .scale(zoom_scale);

      d3.selectAll("[data-terminal-symbol]")
        .transition().duration(transition_duration)
        .style("background-color", "#ffffff");

      d3.select(this)
        .transition().duration(transition_duration)
        .style("background-color", color_focused);

      viewport_group
        .transition().duration(transition_duration)
        .call(zoom.transform, transform);
      model_group.selectAll(".nodes rect")
        .transition().duration(transition_duration)
        .attr("fill", color_fill);
      node_group.select("rect")
        .transition().duration(transition_duration)
        .attr("fill", color_focused);
    });

    $(".tree-head").on("click", function () {
      var $icon = $(".tree-head > .icon")
        .attr("class", "icon fa fa-spinner fa-spin");
      if ($tree.is(":visible")) {
        $tree.hide(transition_duration, function () {
          $icon.attr("class", "icon fa fa-plus-square-o");
        });
      } else {
        $tree.show(transition_duration, function () {
          $icon.attr("class", "icon fa fa-minus-square-o");
        });
      }
    });

    var svg = d3.select(".tree")
      .append("svg")
        .attr("width", tree_width)
        .attr("height", tree_height)
        .style("display", "block");

    viewport_group = svg.append("g")
      .classed("viewport", true)
      .call(zoom.on("zoom", function () {
        var transform = d3.event.transform;
        zoom_x = transform.x;
        zoom_y = transform.y;
        zoom_scale = transform.k;
        view_group.attr("transform", transform.toString());
      }));

    viewport_group.append("rect")
      .attr("width", tree_width)
      .attr("height", tree_height)
      .attr("fill-opacity", "0");

    view_group = viewport_group.append("g")
      .classed("view", true);

    viewport_group.call(zoom.transform, initial_transform);

    model_group = view_group.append("g")
      .classed("model", true);

    var root = d3.hierarchy({ $node: $("#_1") }, function (node) {
      var children = [];
      node.$node.children("[data-symbol]").each(function () {
        children.push({ $node: $(this) })
      });
      return children;
    });

    var tree = d3.tree();
    tree.nodeSize([ node_height, node_width ]);
    tree(root);

    model_group.append("g")
      .classed("edges", true)
      .selectAll(".edge")
        .data(root.descendants().slice(1))
        .enter().append("path")
          .classed("edge", true)
          .attr("d", function (d) {
            var p = d.parent;
            var sx = p.y;
            var sy = p.x;
            var ex = d.y;
            var ey = d.x;
            var mx = (sx + ex) * 0.5;
            var path = d3.path();
            path.moveTo(sx, sy);
            path.bezierCurveTo(mx, sy, mx, ey, ex, ey)
            return path.toString();
          })
          .attr("fill", "none")
          .attr("stroke", color_stroke);

    model_group.append("g")
      .classed("nodes", true)
      .selectAll(".node")
        .data(root.descendants())
        .enter().append("g")
          .classed("node", true)
          .each(function (d) {
            var node_group = d3.select(this);
            var $node = d.data.$node;
            $node.data("node_group", node_group);
            var group = node_group.append("g");
            var rect = group.append("rect")
              .attr("fill", color_fill)
              .attr("stroke", color_stroke);
            var text = group.append("text")
              .text($node.attr("data-symbol-name"));
            var bbox = text.node().getBBox();
            var x = bbox.x;
            var y = bbox.y;
            var w = bbox.width;
            var h = bbox.height;
            var r = h * 0.5;
            rect
              .attr("x", x - r)
              .attr("y", y)
              .attr("width", w + h)
              .attr("height", h)
              .attr("rx", r)
              .attr("rx", r);
            group
              .attr("transform", "translate(" + (- w * 0.5) + "," + (- y - r) + ")");
            var tx = d.y - w * 0.5;
            var ty = d.x - y - r;
            d.data.tx = d.y;
            d.data.ty = d.x;
            node_group
              .attr("transform", "translate(" + d.y + "," + d.x + ")");
          });
  });
}(this));
]]

write_html(io.stdout, { "html";
  { "head";
    { "meta"; charset="utf-8"; };
    { "title"; "lua-to-html" };
    { "link"; rel = "stylesheet"; href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css" };
    { "style"; style };
  };
  { "body";
    { "div"; class="body";
      number_html;
      { "div"; class="code"; root_html };
      panel_html;
    };
    { "script"; src = "https://cdnjs.cloudflare.com/ajax/libs/jquery/3.2.1/jquery.min.js" };
    { "script"; src = "https://cdnjs.cloudflare.com/ajax/libs/URI.js/1.18.12/URI.min.js" };
    { "script"; src = "https://cdnjs.cloudflare.com/ajax/libs/d3/4.10.0/d3.min.js" };
    { "script"; script };
  };
})
io.write("\n")
