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

local builder_node = require "dromozoa.parser.syntax_tree.builder_node"

local private_tree = function () end

local class = {}

function class.new(tree)
  return {
    [private_tree] = tree;
  }
end

function class:get(key)
  local tree = self[private_tree]
  return builder_node(tree:create_node("ref", key))
end

function class:set(key, that)
  local tree = self[private_tree]
  local node = tree:create_node("=", key)
  node:append_child(that.node)
  tree:start():append_child(node)
end

function class:epsilon()
  local tree = self[private_tree]
  return builder_node(tree:create_node("epsilon"))
end

local metatable = {
  __index = class.get;
  __newindex = class.set;
  __call = class.epsilon;
}

return setmetatable(class, {
  __call = function (_, tree)
    return setmetatable(class.new(tree), metatable)
  end;
})
