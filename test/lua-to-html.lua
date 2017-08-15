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
    local value = table.concat(node, 2, number_keys[n])
    out:write(">")
    if value:find("[<&]") then
      out:write(value)
    else
      assert(not value:find("%]%]>"))
      if name == "script" then
        out:write("//<![CDATA[\n", value, "//]]>")
      else
        out:write("/*<![CDATA[*/\n", value, "/*]]>*/")
      end
    end
    out:write("</", name, ">")
  else
    if n > 1 then
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
    else
      out:write("/>")
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
            class = "skip";
            source:sub(p, i - 1);
          }
        end
        parent_html[#parent_html + 1] = { "span";
          id = u.id;
          ["data-symbol-name"] = symbol_names[symbol];
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
        id = id;
        ["data-symbol-name"] = symbol_names[symbol];
      }
    end

    local n = u.n
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

local code_html = root.html
local node = terminal_nodes[#terminal_nodes]
local p = node.p
local i = node.i
if p < i then
  code_html[#code_html + 1] = { "span";
    class = "skip";
    source:sub(p, i - 1);
  }
end

local line_count
if source:find("\n$") then
  line_count = 0
else
  line_count = 1
end
for _ in source:gmatch("\n") do
  line_count = line_count + 1
end

local number_html = { "div"; class="number" }
for i = 1, line_count do
  number_html[#number_html + 1] = { "span";
    i;
    "\n";
  }
end

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
}

.source {
  font-family: 'Noto Sans Mono CJK JP', monospace;
  white-space: pre;
  font-weight: 400;
}

.number {
  width: ]] .. "3ex" .. [[;
  float: left;
  text-align: right;
  padding-right: 1ex;
}

.code {
  float: left;
}

.skip {
  color: red;
}
]]

write_html(io.stdout, { "html";
  { "head";
    { "meta"; charset="utf-8"; };
    { "title"; "lua-to-html" };
    { "style"; style };
  };
  { "body";
    { "div"; class="source";
      number_html;
      { "div"; class="code"; code_html };
    }
  };
})
io.write("\n")
