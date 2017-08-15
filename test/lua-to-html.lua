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

local escape_html = require "dromozoa.parser.escape_html"
local lua53_lexer = require "dromozoa.parser.lexers.lua53_lexer"
local lua53_parser = require "dromozoa.parser.parsers.lua53_parser"

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
local terminal_nodes = assert(lexer(source, file))
local root = assert(parser(terminal_nodes, source, file))
parser:write_graphviz("test.dot", root)

local out = io.stdout
out:write([[
<html>
<!DOCTYPE html>
<html lang="ja">
  <head>
    <meta charset="utf-8">
    <title>lua-to-html</title>
    <style>
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
        color: white;
        background-color: black;
        margin: 0;
      }
      .source {
        font-family: 'Noto Sans Mono CJK JP', monospace;
        white-space: pre;
        font-weight: 400;
      }

      .skip {
        color: red;
      }
      .terminal-symbol-2,
      .terminal-symbol-3,
      .terminal-symbol-4,
      .terminal-symbol-5,
      .terminal-symbol-6,
      .terminal-symbol-7,
      .terminal-symbol-8,
      .terminal-symbol-9,
      .terminal-symbol-10,
      .terminal-symbol-11,
      .terminal-symbol-12,
      .terminal-symbol-13,
      .terminal-symbol-14,
      .terminal-symbol-15,
      .terminal-symbol-16,
      .terminal-symbol-17,
      .terminal-symbol-18,
      .terminal-symbol-19,
      .terminal-symbol-20,
      .terminal-symbol-21,
      .terminal-symbol-22,
      .terminal-symbol-23 {
        color: yellow;
      }
    </style>
  </head>
  <body>
    <div class="source">]])
for i = 1, #terminal_nodes do
  local u = terminal_nodes[i]
  local p = u.p
  local i = u.i
  local j = u.j
  if p < i then
    io.write('<span class="skip">', escape_html(source:sub(p, i - 1)), '</span>')
  end
  io.write('<span class="terminal-symbol-', u[0], '">', escape_html(source:sub(i, j)), '</span>')
end
out:write([[</div>
  </body>
</html>
]])
