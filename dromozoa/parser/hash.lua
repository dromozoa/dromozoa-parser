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

local function hash(key)
  local t = type(key)
  if t == "number" then
    return murmur_hash3.double(key, 1)
  elseif t == "string" then
    return murmur_hash3.string(key, 2)
  elseif t == "boolean" then
    if key then
      return murmur_hash3.uint32(1, 3)
    else
      return murmur_hash3.uint32(0, 3)
    end
  elseif t == "table" then
    local h = murmur_hash3.uint64(#key, 4)
    for i = 1, #key do
      h = murmur_hash3.uint32(hash(key[i]), h)
    end
    return h
  end
end

return hash
