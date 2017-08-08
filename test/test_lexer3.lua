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

local P = builder.pattern
local R = builder.range
local S = builder.set
local RE = builder.regexp

local _ = builder()

_:lexer()
-- :_ (S" \r\n\t\v\f"^"+") :skip()
  :_ (RE[[\s+]]) :skip()
-- :_ ("--" * ((-S"\n")^"*") "\n") :skip()
  :_ (RE[[--[^\n]*\n]]) :skip()
-- :_ ([[\u]] * S"Dd" * S"89ABab" * R"09AFaf"^{2} * [[\u]] * S"Dd" * R"CFcf" * R"09AFaf"^{2}) :as "pair" :utf8_surrogate_pair(3, 6, 9, 12)
  :_ (RE[[\\u[Dd][89ABab][0-9A-Fa-f]{2}\\u[Dd][C-Fc-f][0-9A-Fa-f]{2}]])  :as "pair" :utf8_surrogate_pair(3, 6, 9, 12)
-- :_ ([[\u]] * R"09AFaf"^{4}) :as "char" :utf8(3, -1)
  :_ (RE[[\\u[0-9A-Fa-f]{4}]]) :as "char" :utf8(3, -1)
-- :_ ([[\U]] * R"09AFaf"^{8}) :as "char" :utf8(3, -1)
  :_ (RE[[\\U[0-9A-Fa-f]{8}]]) :as "char" :utf8(3, -1)
-- :_ ([[\c]] * R"AZaz") :as "control" :sub(3, -1) :int(36) :add(-9) :char()
  :_ (RE[=[\\c[A-Za-z]]=]) :as "control" :sub(3, -1) :int(36) :add(-9) :char()
  :_ (RE[[\\x[0-9A-Fa-f]{2}]]) :as "hex" :sub(3, -1) :int(16) :char()

local lexer = _:build()

local source = [[
-- comment
\u65e5\u672c\u8a9e -- 日本語
\U00010437 -- string.char(0xf0, 0x90, 0x90, 0xb7)
\uD801\uDC37
\cM
\x40
]]

local position = 1
local data = {}
repeat
  local symbol, p, i, j, rs, ri, rj = assert(lexer(source, position))
  if symbol ~= 1 then
    data[#data + 1] = rs:sub(ri, rj)
  end
  position = j
until symbol == 1

assert(data[1] == "日")
assert(data[2] == "本")
assert(data[3] == "語")
assert(data[4] == string.char(0xf0, 0x90, 0x90, 0xb7))
assert(data[5] == string.char(0xf0, 0x90, 0x90, 0xb7))
assert(data[6] == "\r")
assert(data[7] == "@")
