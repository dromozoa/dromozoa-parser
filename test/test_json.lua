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

local unix = require "dromozoa.unix"
local builder = require "dromozoa.parser.builder"
local driver = require "dromozoa.parser.driver"

local RE = builder.regexp
local _ = builder()

local lexer_only = true

local source = "[]"
if arg[1] == "-" then
  source = io.read("*a")
else
  source = arg[1]
end

_:lexer()
  :_ "["
  :_ "{"
  :_ "]"
  :_ "}"
  :_ ":"
  :_ ","
  :_ (RE[[[ \t\n\r]+]]) :skip()
  :_ "false"
  :_ "null"
  :_ "true"
  :_ (RE[[-?(0|[1-9]\d*)(\.\d+)?([eE][+-]?\d+)?]]) :as "number"
  :_ (RE[["[^\\"]*"]]): as "string" :sub(2, -2)
  :_ "\"" :call "string" :mark() :skip()

_:lexer "string"
  :_ [[\"]] "\"" :push()
  :_ [[\\]] "\\" :push()
  :_ [[\/]] "/" :push()
  :_ [[\b]] "\b" :push()
  :_ [[\f]] "\f" :push()
  :_ [[\n]] "\n" :push()
  :_ [[\r]] "\r" :push()
  :_ [[\t]] "\t" :push()
  :_ (RE[[\\u[Dd][89ABab][0-9A-Fa-f]{2}\\u[Dd][CFcf][0-9A-Fa-f]{2}]]) :utf8_surrogate_pair(3, 6, 9, 12) :push()
  :_ (RE[[\\u[0-9A-Fa-f]{4}]]) :utf8(3, -1) :push()
  :_ (RE[[[^\\"]+]]) :push()
  :_ "\"" :as "string" :concat() :ret()

if lexer_only then
  local lexer = _:build()

  local timer = unix.timer()
  timer:start()

--[[
  local data = assert(lexer:exp(source, 1))
]]
  local position = 1
  local data = {}
  repeat
    local symbol, p, i, j, rs, ri, rj = assert(lexer(source, position))
    if symbol ~= 1 then
      data[#data + 1] = { symbol, p, i, j, rs, ri, rj }
    end
    position = j
  until symbol == 1

  timer:stop()
  print(timer:elapsed())
else
  _"JSON-text"
    :_ "value"

  _"value"
    :_ "false"
    :_ "null"
    :_ "true"
    :_ "object"
    :_ "array"
    :_ "number"
    :_ "string"

  _"object"
    :_ "{" "}"
    :_ "{" "members" "}"

  _"members"
    :_ "member"
    :_ "members" "," "member" :collapse()

  _"member"
    :_ "string" ":" "value"

  _"array"
    :_ "[" "]"
    :_ "[" "values" "]"

  _"values"
    :_ "value"
    :_ "values" "," "value" :collapse()

  local lexer, grammar = _:build()
  local parser, conflicts = grammar:lr1_construct_table(grammar:lalr1_items())
  grammar:write_conflicts(io.stderr, conflicts, true)
  local driver = driver(lexer, parser)

  local timer = unix.timer()
  timer:start()
  local root = driver(source)
  timer:stop()
  print(timer:elapsed())

  parser:write_graphviz("test.dot", root)
end
