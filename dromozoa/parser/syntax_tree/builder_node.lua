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

local function create_binary_expression(tag, a, b)
  local node = a:tree():create_node(tag)
  node:append_child(a)
  node:append_child(b)
  return node
end

local class = {}

function class.new(node)
  return {
    node = node;
  }
end

function class:branch(that)
  return class(create_binary_expression("|", self.node, that.node))
end

function class:concat(that)
  return class(create_binary_expression("concat", self.node, that.node))
end

local metatable = {
  __add = class.branch;
  __mul = class.concat;
}

return setmetatable(class, {
  __call = function (_, node)
    return setmetatable(class.new(node), metatable)
  end;
})