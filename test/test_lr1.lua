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
local sequence = require "dromozoa.commons.sequence"
local sequence_writer = require "dromozoa.commons.sequence_writer"
local xml = require "dromozoa.commons.xml"
local grammar = require "dromozoa.parser.builder.grammar"

local TO = string.char(0xE2, 0x86, 0x92) -- U+2192 RIGHWARDS ARROW
local DOT = string.char(0xC2, 0xB7) -- U+00B7 MIDDLE DOT
local EOF = "$"

local function dump_item(out, g, item)
  local productions = g.productions
  local symbols = g.symbols
  local production = productions[item.id]
  local body = production.body
  local dot = item.dot
  local la = item.la
  out:write(symbols[production.head], " ", TO)
  for i, symbol in ipairs(body) do
    if i == dot then
      out:write(" ", DOT)
    end
    out:write(" ", symbols[symbol])
  end
  if dot == #body + 1 then
    out:write(" ", DOT)
  end
  out:write(", ")
  if la == 0 then
    out:write(EOF)
  else
    out:write(symbols[la])
  end
  return out
end

local function dump_items(g, items)
  for item in items:each() do
    dump_item(io.stdout, g, item)
    io.write("\n")
  end
end

local function write_graph(g, set_of_items, transitions, filename)
  local symbols = g.symbols

  local out = assert(io.open(filename, "w"))
  out:write([[
digraph g {
graph [rankdir=LR];
node [shape=plaintext]
]])

  for i, items in ipairs(set_of_items) do
    out:write(("%d [label=<<table border=\"1\" cellborder=\"0\" cellpadding=\"0\" cellspacing=\"0\" margin=\"0\">"):format(i))
    out:write(("<tr><td>I%d</td></tr>"):format(i))
    for item in items:each() do
      out:write(("<tr><td align=\"left\" bgcolor=\"%s\">%s</td></tr>"):format(
          g:is_kernel_item(item) and "white" or "grey",
          xml.escape(dump_item(sequence_writer(), g, item):concat())))
    end
    out:write("</table>>]\n")
  end

  for transition in transitions:each() do
    out:write(([[
%d->%d [label=<%s>];
]]):format(transition.from, transition.to, xml.escape(symbols[transition.symbol])))
  end

  out:write("}\n")
  out:close()
end

local _ = grammar()

_"S" (_"C", _"C")
_"C" ("c", _"C") ("d")

local g = _():argument()
print(dumper.encode(g, { pretty = true, stable = true }))

-- S' -> dot S, $
local I = sequence():push({ id = 4, dot = 1, la = 0 })
print("--")
dump_items(g, I)

-- S' -> dot S, $
-- S -> dot C C, $
-- C -> dot c C, c/d
-- C -> dot d, c/d
g:lr1_closure(I)
print("--")
dump_items(g, I)

local set_of_items, transitions = g:lr1_items()
for i, items in ipairs(set_of_items) do
  io.write(("======== I_%d ==========\n"):format(i))
  dump_items(g, items)
end

write_graph(g, set_of_items, transitions, "test.dot")
