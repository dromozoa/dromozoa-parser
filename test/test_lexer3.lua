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

local builder = require "dromozoa.parser.builder"
local symbol_value = require "dromozoa.parser.symbol_value"

local RE = builder.regexp

local _ = builder()

_:lexer()
  :_(RE[[\s+]]) :skip()
  :_(RE[[--[^\n]*\n]]) :skip()
  :_(RE[[\\u[Dd][89ABab][0-9A-Fa-f]{2}\\u[Dd][C-Fc-f][0-9A-Fa-f]{2}]]) :as "pair" :utf8(3, 6, 9, 12)
  :_(RE[[\\u[0-9A-Fa-f]{4}]]) :as "char" :utf8(3)
  :_(RE[[\\U[0-9A-Fa-f]{8}]]) :as "char" :utf8(3)
  :_(RE[=[\\c[A-Za-z]]=]) :as "control" :sub(3) :int(36) :add(-9) :char()
  :_(RE[[\\x[0-9A-Fa-f]{2}]]) :as "hex" :sub(3) :int(16) :char()

local lexer = _:build()

local source = [[
\u65e5\u672c\u8a9e -- 日本語
\U00010437 -- string.char(0xf0, 0x90, 0x90, 0xb7)
\uD801\uDC37
\cM
\x40
]]

local result = assert(lexer(source))
assert(symbol_value(result[1]) == "日")
assert(symbol_value(result[2]) == "本")
assert(symbol_value(result[3]) == "語")
assert(symbol_value(result[4]) == string.char(0xf0, 0x90, 0x90, 0xb7))
assert(symbol_value(result[5]) == string.char(0xf0, 0x90, 0x90, 0xb7))
assert(symbol_value(result[6]) == "\r")
assert(symbol_value(result[7]) == "@")
