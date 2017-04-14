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

local linked_hash_table = require "dromozoa.commons.linked_hash_table"
local symbol = require "dromozoa.parser.symbol"

local class = {}

function class.new(type)
  return {
    type = type;
    count = 0;
    symbols = linked_hash_table();
  }
end

class.metatable = {
  __index = class;
}

function class.metatable:__call(name)
  local symbols = self.symbols
  local s = symbols[name]
  if s == nil then
    local id = self.count + 1
    self.count = id
    s = symbol(self.type, id)
    symbols[name] = s
  end
  return s
end

return setmetatable(class, {
  __call = function (_, type)
    return setmetatable(class.new(type), class.metatable)
  end;
})
