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

local symbol = require "dromozoa.parser.builder.symbol"

local super = symbol
local class = {}

function class.new(tag, id, name, grammar)
  local self = super(tag, id, name)
  self.grammar = grammar
  return self
end

function class:body(...)
  self.grammar:production(self, ...)
  return self
end

class.metatable = {
  __index = class;
  __call = class.body;
}

return setmetatable(class, {
  __index = super;
  __call = function (_, tag, id, name, grammar)
    return setmetatable(class.new(tag, id, name, grammar), class.metatable)
  end;
})
