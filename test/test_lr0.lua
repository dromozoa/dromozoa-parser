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

local function dump_item(out, g, item)
  local productions = g.productions
  local symbols = g.symbols
  local production = productions[item.id]
  local body = production.body
  local dot = item.dot
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

  for transition, to in transitions:each() do
    out:write(([[
%d->%d [label=<%s>];
]]):format(transition.from, to, xml.escape(symbols[transition.symbol])))
  end

  out:write("}\n")
  out:close()
end

local _ = grammar()

_"E" (_"E", "+", _"T") (_"T")
_"T" (_"T", "*", _"F") (_"F")
_"F" ("(", _"E", ")") ("id")

local g = _():argument()
-- print("--")
-- print(dumper.encode(g, { pretty = true }))

-- E' -> dot E
local I = sequence():push():push({ id = 7, dot = 1 })
-- print("--")
-- print(dumper.encode(I, { pretty = true }))
-- dump_items(g, I)

-- E' -> dot E
-- E -> dot E + T
-- E -> dot T
-- T -> dot T * F
-- T -> dot F
-- F -> dot ( E )
-- F -> dot id
g:lr0_closure(I)
-- print("--")
-- print(dumper.encode(I, { pretty = true }))
-- dump_items(g, I)

-- E' -> E dot
-- E -> E dot + T
local I = sequence()
  :push({ id = 7, dot = 2 })
  :push({ id = 1, dot = 2 })
-- print("--")
-- dump_items(g, I)

-- E -> E + dot T
-- T -> dot T * F
-- T -> dot F
-- F -> dot ( E )
-- F -> dot id
local J = g:lr0_goto(I)[1]
-- print("--")
-- dump_items(g, J)

local set_of_items, transitions = g:lr0_items()
for i, items in ipairs(set_of_items) do
  io.write(("======== I_%d ==========\n"):format(i))
  dump_items(g, items)
end

write_graph(g, set_of_items, transitions, "test.dot")
