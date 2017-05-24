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

local sequence = require "dromozoa.commons.sequence"
local regexp_builder = require "dromozoa.parser.regexp_builder"

local P = regexp_builder.P

local function rule(self, name, tree)
  self.items:push({
    name = name;
    tree = tree;
  })
  return self
end

local class = {}

function class.new(name)
  return {
    name = name;
    items = sequence();
  }
end

function class:lit(literal)
  return rule(self, literal, P(literal))
end

function class:pat(pattern)
  return rule(self, nil, P(pattern))
end

function class:as(name)
  self.items:top().name = name
  return self
end

function class:ignore()
  self.items:top().action = "ignore"
  return self
end

function class:call(name)
  local item = self.items:top()
  item.action = "call"
  item.arguments = { name }
  return self
end

function class:ret()
  self.items:top().action = "ret"
  return self
end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, name)
    return setmetatable(class.new(name), class.metatable)
  end;
})
