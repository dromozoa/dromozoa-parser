-- Copyright (C) 2015 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local uint32 = require "dromozoa.parser.uint32"

assert(uint32.add(0xFEEDFACE, 0xDEADBEEF) == 0xDD9BB9BD)
assert(uint32.mul(0xFEEDFACE, 0xDEADBEEF) == 0xC1880A52)
assert(uint32.bxor(0xFEEDFACE, 0xDEADBEEF) == 0x20404421)
assert(uint32.shl(0xFEEDFACE, 16) == 0xFACE0000)
assert(uint32.shr(0xFEEDFACE, 16) == 0x0000FEED)
assert(uint32.rotl(0xFEEDFACE, 7) == 0x76FD677F)
assert(uint32.rotl(0xFEEDFACE, 8) == 0xEDFACEFE)
assert(uint32.rotl(0xFEEDFACE, 16) == 0xFACEFEED)
assert(uint32.rotl(0xFEEDFACE, 24) == 0xCEFEEDFA)
assert(uint32.rotr(0xFEEDFACE, 7) == 0x9DFDDBF5)
assert(uint32.rotr(0xFEEDFACE, 8) == 0xCEFEEDFA)
assert(uint32.rotr(0xFEEDFACE, 16) == 0xFACEFEED)
assert(uint32.rotr(0xFEEDFACE, 24) == 0xEDFACEFE)

assert(uint32.bxor(0xFFFFFFFF, 0x00000000) == 0xFFFFFFFF)
assert(uint32.shl(0xFFFFFFFF, 0) == 0xFFFFFFFF)
assert(uint32.shr(0xFFFFFFFF, 0) == 0xFFFFFFFF)
assert(uint32.rotl(0xFFFFFFFF, 0) == 0xFFFFFFFF)
assert(uint32.rotr(0xFFFFFFFF, 0) == 0xFFFFFFFF)
