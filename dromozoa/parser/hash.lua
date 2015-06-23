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

local aformat = require "dromozoa.parser.aformat"
local murmur_hash3 = require "dromozoa.parser.murmur_hash3"

local type = type

local function hash(this)
  local t = type(this)
  if t == "number" then
    return murmur_hash3(aformat(this), 1)
  elseif t == "string" then
    return murmur_hash3(this, 2)
  elseif t == "boolean" then
    if this then
      return murmur_hash3(1, 3)
    else
      return murmur_hash3(0, 3)
    end
  elseif t == "table" then
    local that = murmur_hash3(#this, 4)
    for i = 1, #this do
      that = murmur_hash3(hash(this[i]), that)
    end
    return that
  end
end

return hash
