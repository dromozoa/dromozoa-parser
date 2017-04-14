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
local symbols = require "dromozoa.parser.symbols"
local productions = require "dromozoa.parser.productions"

--[[
terminals / tokens
nonterminals
grammar
start symbol
productions
production
  head / left side
  -> / ::=
  body / right side
]]

local T = symbols("terminal")
local N = symbols("nonterminal")
local P = productions()

P(N"expression", N"expression", T"+", N"term")
P(N"expression", N"expression", T"-", N"term")
P(N"expression", N"term")
P(N"term", N"term", T"*", N"factor")
P(N"term", N"term", T"/", N"factor")
P(N"term", N"factor")
P(N"factor", T"(", N"expression", T")")
P(N"factor", T"id")

-- print(dumper.encode(T, { pretty = true }))
-- print(dumper.encode(N, { pretty = true }))
-- print(dumper.encode(P, { pretty = true }))

P:write(io.stdout)
