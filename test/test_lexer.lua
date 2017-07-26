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

local equal = require "dromozoa.commons.equal"
local builder = require "dromozoa.parser.builder"

local P = builder.pattern
local R = builder.range
local S = builder.set

local _ = builder()

_:lexer()
  :_ (S" \r\n\t\v\f"^"+") :skip()
  :_ "="
  :_ "*"
  :_ "+"
  :_ "("
  :_ ")"
  :_ (R"AZ__az" * R"09AZ__az"^"*") :as "identifier"
  :_ (R"09"^"+") :as "integer"
  :_ [["]] :call "string" :skip()

_:lexer "string"
  :_ [["]] :as "string" :concat() :ret()
  :_ [[\r]] "\r" :push()
  :_ [[\n]] "\n" :push()
  :_ [[\t]] "\t" :push()
  :_ [[\v]] "\v" :push()
  :_ [[\f]] "\f" :push()
  :_ [[\"]] "\"" :push()
  :_ ((-S'\\"')^"+") :push()

local lexer = _:build()

local s = [[
12 + 34 * 56 "test\tabc" "\"foo\""
abcdefgh
abcdefg
abcdef
abcde
abcd
]]

for i = 1, 8 do
  local source = s .. (" "):rep(i)
  local symbol
  local position = 1
  local rs
  local ri
  local rj

  local data = {}
  repeat
    symbol, position, rs, ri, rj = assert(lexer(source, position))
    data[#data + 1] = { _.symbol_names[symbol], rs:sub(ri, rj) }
    if i == 1 then
      print(_.symbol_names[symbol], symbol, ("%q"):format(rs:sub(ri, rj)))
    end
  until symbol == 1

  assert(equal(data, {
    { "integer", "12" };
    { "+", "+" };
    { "integer", "34" };
    { "*", "*" };
    { "integer", "56" };
    { "string", "test\tabc" };
    { "string", "\"foo\"" };
    { "identifier", "abcdefgh" };
    { "identifier", "abcdefg" };
    { "identifier", "abcdef" };
    { "identifier", "abcde" };
    { "identifier", "abcd" };
    { "$", "" };
  }))
end
