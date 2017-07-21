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

local ipairs = require "dromozoa.commons.ipairs"
local json = require "dromozoa.commons.json"
local sequence_writer = require "dromozoa.commons.sequence_writer"
local xml = require "dromozoa.commons.xml"

local TO = string.char(0xE2, 0x86, 0x92) -- U+2192 RIGHWARDS ARROW
local DOT = string.char(0xC2, 0xB7) -- U+00B7 MIDDLE DOT
local LA = "#"
local EPSILON = string.char(0xCE, 0xB5) -- U+03B5 GREEK SMALL LETTER EPSILON

local class = {}

function class.new(symbol_names, productions, max_terminal_symbol)
  return {
    symbol_names = symbol_names;
    productions = productions;
    max_terminal_symbol = max_terminal_symbol;
  }
end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, symbol_names, productions, max_terminal_symbol)
    return setmetatable(class.new(symbol_names, productions, max_terminal_symbol), class.metatable)
  end;
})
