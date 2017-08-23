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
local value = require "dromozoa.parser.value"
local lua53_lexer = require "dromozoa.parser.lexers.lua53_lexer"
local lua53_parser = require "dromozoa.parser.parsers.lua53_parser"

local encode_string = dumper.encode_string
local keys = dumper.keys
local symbol_value = value

local function ref_constant(state, u, type, value)
  local constants = state.constants
  local n = #constants
  for i = n, 1, -1 do
    local constant = constants[i]
    if constant.type == type and constant.value == value then
      local refs = constant.refs
      refs[#refs + 1] = u
      return
    end
  end
  constants[n + 1] = {
    type = type;
    value = value;
    refs = { u };
  }
end

local function def_name(scope, u, type, value)
  local names = scope.names
  names[#names + 1] = {
    type = type;
    value = value;
    def = u.id;
    refs = {};
  }
end

local function ref_name(scope, u, value)
  while true do
    local names = scope.names
    local n = #names
    for i = n, 1, -1 do
      local name = names[i]
      if name.value == value then
        local refs = name.refs
        refs[#refs + 1] = u.id
        return
      end
    end
    local parent = scope.parent
    if parent then
      scope = parent
    else
      names[#names + 1] = {
        value = value;
        refs = { u.id };
      }
      return
    end
  end
end

local function def_label(scope, u, value)
  local labels = scope.labels
  labels[#labels + 1] = {
    type = type;
    value = value;
    def = u.id;
    refs = {};
  }
end

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

local function add_state_html(state_html, state)
  if state then
    local constants = state.constants
    if constants[1] then
      local constant_tbody_html = { "tbody" }
      for i = 1, #constants do
        local constant = constants[i]
        local t = constant.type
        local v = constant.value
        if t == "string" then
          v = encode_string(v)
        end
        local refs = constant.refs
        local refs_html = { "td" }
        for j = 1, #refs do
          local ref = refs[j]
          local n = #refs_html
          if n == 1 then
            refs_html[n + 1] = { "span";
              ["data-ref"] = ref.id;
              "#" .. ref.id;
            }
          else
            refs_html[n + 1] = ","
            refs_html[n + 2] = { "span";
              ["data-ref"] = ref.id;
              "#" .. ref.id;
            }
          end
        end
        constant_tbody_html[#constant_tbody_html + 1] = { "tr";
          { "td"; t };
          { "td"; v };
          refs_html;
        }
      end

      state_html[#state_html + 1] = { "div";
        { "span"; ["data-ref"] = state.id; "Constants" };
        { "table";
          { "thead";
            { "tr";
              { "th"; "Type" };
              { "th"; "Value" };
              { "th"; "Refs" };
            };
          };
          constant_tbody_html;
        };
      }
    end
  end
end

local function add_scope_html(scope_html, scope)
  if scope then
    local names = scope.names
    if names[1] then
      local name_tbody_html = { "tbody" }
      for i = 1, #names do
        local name = names[i]
        local def = name.def
        local def_html = { "td"; ["data-ref"] = def }
        if def then
          def_html[#def_html + 1] = "#" .. def
        end
        local refs = name.refs
        local refs_html = { "td" }
        for j = 1, #refs do
          local ref = refs[j]
          local n = #refs_html
          if n == 1 then
            refs_html[n + 1] = { "span";
              ["data-ref"] = ref;
              "#" .. ref;
            }
          else
            refs_html[n + 1] = ","
            refs_html[n + 2] = { "span";
              ["data-ref"] = ref;
              "#" .. ref;
            }
          end
        end
        name_tbody_html[#name_tbody_html + 1] = { "tr";
          { "td"; name.type };
          { "td"; name.value };
          def_html;
          refs_html;
        }
      end

      scope_html[#scope_html + 1] = { "div";
        { "span"; ["data-ref"] = scope.id; "Names" };
        { "table";
          { "thead";
            { "tr";
              { "th"; "Type" };
              { "th"; "Name" };
              { "th"; "Def" };
              { "th"; "Refs" };
            };
          };
          name_tbody_html;
        };
      }
    end

    local labels = scope.labels
    if labels[1] then
      local label_tbody_html = { "tbody" }
      for i = 1, #labels do
        local label = labels[i]
        local def = label.def
        label_tbody_html[#label_tbody_html + 1] = { "tr";
          { "td"; label.value };
          { "td"; ["data-ref"] = def; "#" .. def };
          { "td" };
        }
      end

      scope_html[#scope_html + 1] = { "div";
        { "span"; ["data-ref"] = scope.id; "Labels" };
        { "table";
          { "thead";
            { "tr";
              { "th"; "Name" };
              { "th"; "Def" };
              { "th"; "Refs" };
            };
          };
          label_tbody_html;
        };
      }
    end
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
local symbol_table = parser.symbol_table
local max_terminal_symbol = parser.max_terminal_symbol
local terminal_nodes = assert(lexer(source, file))
local root = assert(parser(terminal_nodes, source, file))

local id = 0
local state
local env = {
  names = {};
  labels = {};
}
local scope = env

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

    if u.state then
      state = state.parent
    end

    if u.scope then
      scope = scope.parent
    end

    local symbol = u[0]
    if symbol == symbol_table.label then
      local v = u[2]
      def_label(scope, v, symbol_value(v))
    elseif symbol == symbol_table.local_name then
      local v = u[1]
      def_name(scope, v, "var", symbol_value(v))
    elseif symbol == symbol_table.local_namelist then
      local v = u[1]
      for i = 1, #v, 2 do
        local w = v[i]
        def_name(scope, w, "var", symbol_value(w))
      end
    elseif symbol == symbol_table.parlist then
      local v = u[1]
      if v[0] == symbol_table.namelist then
        for i = 1, #v, 2 do
          local w = v[i]
          def_name(scope, w, "param", symbol_value(w))
        end
        local w = u[3]
        if w then
          def_name(scope, w, "...", symbol_value(w))
        end
      else
        def_name(scope, v, "...", symbol_value(v))
      end
    elseif symbol == symbol_table.var then
      local v = u[1]
      if v[0] == symbol_table.Name then
        ref_name(scope, v, symbol_value(v))
      end
    elseif symbol == symbol_table.LiteralString then
      ref_constant(state, u, "string", symbol_value(u));
    elseif symbol == symbol_table.IntegerConstant then
      ref_constant(state, u, "integer", tonumber(symbol_value(u)))
    elseif symbol == symbol_table.FloatConstant then
      ref_constant(state, u, "float", tonumber(symbol_value(u)))
    end
  else
    id = id + 1
    u.id = id

    if u.state then
      state = {
        id = id;
        parent = state;
        constants = {};
        locals = {};
        upvalues = {};
      }
      u.state = state
    end

    if u.scope then
      scope = {
        id = id;
        parent = scope;
        names = {};
        labels = {};
      }
      u.scope = scope
    end

    local order = u.order
    if order then
      local n = #order
      for i = 1, n do
        u[order[i]].parent = u
      end
      for i = #order, 1, -1 do
        stack1[#stack1 + 1] = u[order[i]]
      end
    else
      local n = #u
      for i = 1, n do
        u[i].parent = u
      end
      for i = n, 1, -1 do
        stack1[#stack1 + 1] = u[i]
      end
    end
    stack2[n2 + 1] = u
  end
end

local scope_html = { "div"; class = "scope" }
add_scope_html(scope_html, env)

local state_html = { "div"; class = "state" }

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
    local symbol = u[0]
    if symbol > max_terminal_symbol then
      local order = u.order
      if order then
        order = table.concat(order, ",")
      end
      add_state_html(state_html, u.state)
      add_scope_html(scope_html, u.scope)
      u.html = { "span",
        id = "_" .. u.id;
        ["data-symbol"] = symbol;
        ["data-symbol-name"] = symbol_names[symbol];
        ["data-order"] = order;
      }
    end
    local n = #u
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
    class = "color-number";
    i;
    "\n";
  }
end

local panel_width_rem = 40
local panel_html = { "div"; class="panel";
  { "div"; class = "panel-head";
    { "span"; class = "icon fa fa-minus-square-o" };
    { "span"; "Tree" };
  };
  { "div"; class = "tree" };
  { "div"; class = "panel-head";
    { "span"; class = "icon fa fa-minus-square-o" };
    { "span"; "State" };
  };
  state_html;
  { "div"; class = "panel-head";
    { "span"; class = "icon fa fa-minus-square-o" };
    { "span"; "Scope" };
  };
  scope_html;
}

local transition_duration = 400

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

  background-color: #FFFFFF; /* actual_white */
  color: #424242; /* light_black */
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

.state, .scope {
  height: 30rem;
  overflow: scroll;
}

.panel-head {
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

.code span {
  transition: background-color ]] .. transition_duration .. [[ms;
}

.code span.color-active {
  background-color: #F3E430; /* yellow */
  transition: background-color ]] .. transition_duration .. [[ms;
}

.viewport > rect {
  fill-opacity: 0;
}

.edge path {
  fill: none;
  stroke: #000000;
}

.node rect {
  fill: #FFFFFF; /* actual_white */
  stroke: #000000;
  transition: fill ]] .. transition_duration .. [[ms;
}

.node rect.color-active {
  fill: #F3E430; /* yellow */
  transition: fill ]] .. transition_duration .. [[ms;
}

.state table,
.scope table {
  border-collapse: collapse;
}

.state th,
.state td,
.scope th,
.scope td {
  border: solid 1px #000000;
}
]]

local script = [[
(function (root) {
  var setTimeout = root.setTimeout;
  var $ = root.jQuery;
  var d3 = root.d3;

  var panel_width_rem = ]] .. panel_width_rem .. [[;
  var transition_duration = ]] .. transition_duration .. [[;

  var update_node_group = function (node_group) {
    var group = node_group.select("g");
    var rect = group.select("rect");
    var text = group.select("text");
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
  };

  var update_node_groups = function (count) {
    d3.selectAll("g.node").each(function (d) {
      update_node_group(d3.select(this));
    });
    if (--count > 0) {
      setTimeout(function () {
        update_node_groups(count);
      }, 200);
    }
  };

  $(function () {
    var $tree = $(".tree");
    var tree_width = $tree.width();
    var tree_height = $tree.height();
    var rem = tree_width / panel_width_rem;

    var node_width = 10 * rem;
    var node_height = 2 * rem;

    var initial_zoom_x = node_width * 0.5;
    var initial_zoom_y = tree_height * 0.5;
    var initial_zoom_scale = 1;
    var initial_transform = d3.zoomIdentity
      .translate(initial_zoom_x, initial_zoom_y)
      .scale(initial_zoom_scale);

    var zoom = d3.zoom();
    var zoom_x = 0;
    var zoom_y = 0;
    var zoom_scale = 1;

    $("[data-terminal-symbol]").on("click", function () {
      var node_group = $(this).data("node_group");
      var d = node_group.datum();
      var zx = tree_width * 0.5 - d.data.tx * zoom_scale;
      var zy = tree_height * 0.5 - d.data.ty * zoom_scale;
      var transform = d3.zoomIdentity
        .translate(zx, zy)
        .scale(zoom_scale);
      d3.selectAll(".color-active")
        .classed("color-active", false);
      $(this)
        .addClass("color-active");
      node_group.select("rect")
        .classed("color-active", true);
      d3.select("g.viewport")
        .transition().duration(transition_duration)
        .call(zoom.transform, transform);
    });

    $(".panel-head").on("click", function () {
      var $this = $(this);
      var $area = $this.next();
      var $icon = $this.children(".icon")
        .attr("class", "icon fa fa-spinner fa-spin");
      if ($area.is(":visible")) {
        $area.slideUp(transition_duration, function () {
          $icon.attr("class", "icon fa fa-plus-square-o");
        });
      } else {
        $area.slideDown(transition_duration, function () {
          $icon.attr("class", "icon fa fa-minus-square-o");
        });
      }
    });

    $("[data-ref]").on("click", function (ev) {
      ev.stopPropagation();
      var $this = $(this);
      var $node = $("#_" + $this.attr("data-ref"));
      var scroll = $node.offset().top - 1.5 * rem;
      if (scroll < 0) {
        scroll = 0;
      }
      d3.selectAll(".color-active")
        .classed("color-active", false);
      $node
        .addClass("color-active");
      $("body").animate({
        scrollTop: scroll
      }, transition_duration);
    });

    var svg = d3.select(".tree")
      .append("svg")
        .attr("width", tree_width)
        .attr("height", tree_height)
        .style("display", "block");

    var viewport_group = svg.append("g")
      .classed("viewport", true)
      .call(zoom.on("zoom", function () {
        var transform = d3.event.transform;
        zoom_x = transform.x;
        zoom_y = transform.y;
        zoom_scale = transform.k;
        d3.select("g.view").attr("transform", transform.toString());
      }));

    viewport_group.append("rect")
      .attr("width", tree_width)
      .attr("height", tree_height);

    var view_group = viewport_group.append("g")
      .classed("view", true);

    viewport_group.call(zoom.transform, initial_transform);

    var model_group = view_group.append("g")
      .classed("model", true);

    var tree_root = d3.hierarchy({ $node: $("[data-symbol-name=chunk]") }, function (node) {
      var $node = node.$node;
      var order = $node.attr("data-order");
      var children = [];
      $node.children("[data-symbol]").each(function () {
        children.push({ $node: $(this) })
      });
      if (order) {
        var ordered = [];
        $.each(order.split(","), function (i, v) {
          ordered[i] = children[v - 1];
        });
        return ordered;
      } else {
        return children;
      }
    });

    var tree = d3.tree();
    tree.nodeSize([ node_height, node_width ]);
    tree(tree_root);

    model_group.append("g")
      .classed("edges", true)
      .selectAll(".edge")
        .data(tree_root.descendants().slice(1))
        .enter().append("g")
          .classed("edge", true)
          .append("path")
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
            });

    model_group.append("g")
      .classed("nodes", true)
      .selectAll(".node")
        .data(tree_root.descendants())
        .enter().append("g")
          .classed("node", true)
          .each(function (d) {
            var node_group = d3.select(this);
            var $node = d.data.$node;
            $node.data("node_group", node_group);
            group = node_group.append("g");
            group.append("rect");
            group.append("text")
              .text($node.attr("data-symbol-name"));
            d.data.tx = d.y;
            d.data.ty = d.x;
            node_group
              .attr("transform", "translate(" + d.y + "," + d.x + ")")
              .on("click", function (d) {
                var scroll = $node.offset().top - 1.5 * rem;
                if (scroll < 0) {
                  scroll = 0;
                }
                d3.selectAll(".color-active")
                  .classed("color-active", false);
                $node
                  .addClass("color-active");
                d3.select(this).select("rect")
                  .classed("color-active", true);
                $("body").animate({
                  scrollTop: scroll
                }, transition_duration);
              });
            update_node_group(node_group);
          });

    update_node_groups(10);
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
    { "script"; src = "https://cdnjs.cloudflare.com/ajax/libs/d3/4.10.0/d3.min.js" };
    { "script"; script };
  };
})
io.write("\n")
