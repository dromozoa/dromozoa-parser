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

local pairs = require "dromozoa.commons.pairs"
local sequence = require "dromozoa.commons.sequence"
local tree = require "dromozoa.tree"

local marker_end = 1
local start_state = 1

local class = {}

function class.new(grammar, data)
  return {
    productions = grammar.productions;
    max_state = data.max_state;
    max_symbol = data.max_symbol;
    table = data.table;
    states = sequence():push(start_state);
    symbols = sequence();
    tree = tree();
    nodes = sequence();
  }
end

function class:parse(symbol)
  if symbol == nil then
    return self:parse_node({ code = marker_end })
  else
    local tree = self.tree
    local node = tree:create_node()
    for k, v in pairs(symbol) do
      node[k] = v
    end
    return self:parse_node(node)
  end
end

function class:parse_node(node)
  local productions = self.productions
  local max_state = self.max_state
  local max_symbol = self.max_symbol
  local table = self.table
  local states = self.states
  local tree = self.tree
  local nodes = self.nodes

  local state = states:top()
  local action = table[state * max_symbol + node.code]
  if action == 0 then
    error("parse error")
  elseif action <= max_state then
    states:push(action)
    nodes:push(node)
  else
    local reduce = action - max_state
    if reduce == 1 then
      -- return nodes:pop()
    else
      local production = productions[reduce]
      local head = production.head
      local reduce_node = tree:create_node()
      reduce_node.code = head

      local n = #production.body

      local m = #nodes
      for i = 1, n do
        local j = m - n + i
        reduce_node:append_child(nodes[j])
        nodes[j] = nil
      end

      local m = #states
      for i = 1, n do
        local j = m - n + i
        states[j] = nil
      end

      local state = states:top()
      states:push(table[state * max_symbol + head])
      nodes:push(reduce_node)
      return self:parse_node(node)
    end
  end

end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, grammar, data)
    return setmetatable(class.new(grammar, data), class.metatable)
  end;
})
