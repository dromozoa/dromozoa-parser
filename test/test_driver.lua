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

local dumper = require "dromozoa.commons.dumper"
local ipairs = require "dromozoa.commons.ipairs"
local xml = require "dromozoa.commons.xml"
local driver = require "dromozoa.parser.driver"
local grammar = require "dromozoa.parser.builder.grammar"
local dump = require "test.dump"

local _ = grammar()

_"E" (_"E", "+", _"T") (_"T")
_"T" (_"T", "*", _"F") (_"F")
_"F" ("(", _"E", ")") ("id")

local g = _()
print(dumper.encode(g, { pretty = true, stable = true }))

local data = g:lr1_construct_table(g:lalr1_items())
print(dumper.encode(data, { stable = true }))

local _ = {}
for i, name in ipairs(g.symbols) do
  _[name] = i
end

local d = driver(g, data)
-- d:parse({ code = _["("] })
d:parse({ code = _["id"], value = 17 })
d:parse({ code = _["+"] })
d:parse({ code = _["id"], value = 23 })
-- d:parse({ code = _[")"] })
d:parse({ code = _["+"] })
d:parse({ code = _["id"], value = 37 })
local r = d:parse()

function dump.write_tree(filename, g, root)
  local out = assert(io.open(filename, "w"))
  out:write([[
digraph g {
graph [rankdir=TB];
node [shape=plaintext]
]])

  dump.write_tree_node(out, g, root, 1)
  dump.write_tree_edge(out, g, root)

  out:write("}\n")
  out:close()
end

function dump.write_tree_node(out, g, node, id)
  local symbols = g.symbols
  node.id = id
  local code = node.code
  if g:is_terminal_symbol(code) then
    out:write(("%d [label=<<table border=\"0\" cellborder=\"1\" cellpadding=\"0\" cellspacing=\"0\" margin=\"0\">"):format(id))
    out:write(("<tr><td>%s</td></tr>"):format(xml.escape(symbols[code])))
    local value = node.value
    if value then
      out:write(("<tr><td>%s</td></tr>"):format(xml.escape(value)))
    end
    out:write("</table>>]\n")
    return id
  else
    out:write(("%d [label=<<table border=\"0\" cellborder=\"1\" cellpadding=\"0\" cellspacing=\"0\" margin=\"0\">"):format(id))
    out:write(("<tr><td>%s</td></tr>"):format(xml.escape(symbols[code])))
    out:write("</table>>]\n")
    for node in node.body:each() do
      id = dump.write_tree_node(out, g, node, id + 1)
    end
    return id
  end
end

function dump.write_tree_edge(out, g, node)
  local code = node.code
  local id = node.id
  if g:is_nonterminal_symbol(code) then
    for node in node.body:each() do
      out:write(("%d -> %d\n"):format(id, node.id))
      dump.write_tree_edge(out, g, node)
    end
  end
end

dump.write_tree("test.dot", g, r)

