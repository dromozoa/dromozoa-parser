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

local atom = require "dromozoa.parser.builder.atom"
local pattern = require "dromozoa.parser.builder.pattern"

local class = {}

function class.pattern(that)
  local t = type(that)
  if t == "number" then
    if that == 1 then
      return atom.any()
    else
      return pattern.any(that)
    end
  elseif t == "string" then
    if #that == 1 then
      return atom.char(that)
    else
      return pattern.literal(that)
    end
  else
    return that
  end
end

function class.range(that)
  return atom.range(that)
end

function class.set(that)
  return atom.set(that)
end

pattern.super = class

return class
