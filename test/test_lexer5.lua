-- Copyright (C) 2019 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local verbose = os.getenv "VERBOSE" == "1"

local RE = builder.regexp
local _ = builder()

_:lexer()
  :_(RE[[(\r|\n|\r\n|\n\r)]]) :skip() :update_line_number()
  :_(RE[[[ \f\t\v]+]]) :skip()
  :_(RE[[\[=*\[]]) :sub(2, -2) :join("]", "]") :hold() :skip() :call "name" :mark()
  :_(RE[[\S+]]) :as "token"

_:search_lexer "name"
  :when() :as "name" :concat() :normalize_eol() :ret()
  :otherwise() :push()

local lexer = _:build()

local source = "a b\rc d\ne f\r\ng h\n\r j k \n"
local expect = {
  {  1, 1 };
  {  1, 3 };
  {  2, 1 };
  {  2, 3 };
  {  3, 1 };
  {  3, 3 };
  {  4, 1 };
  {  4, 3 };
  {  5, 2 };
  {  5, 4 };
  {  6, 1 };
}

local items = assert(lexer(source))
for i = 1, #items do
  local item = items[i]
  local value = symbol_value(item)
  if verbose then
    print(("%d\t%d\t%d\t%q"):format(item.i, item.n, item.c, value))
  end
  assert(item.n == expect[i][1])
  assert(item.c == expect[i][2])
end
