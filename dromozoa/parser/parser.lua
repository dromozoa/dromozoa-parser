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

local write_graphviz = require "dromozoa.parser.parser.write_graphviz"

local class = {}
local metatable = {
  __index = class;
}
class.metatable = metatable

function class:write_graphviz(out, tree)
  if type(out) == "string" then
    write_graphviz(self, assert(io.open(out, "w")), tree):close()
  else
    return write_graphviz(self, out, tree)
  end
end

function metatable:__call(symbol, data)
  local max_state = self.max_state
  local max_symbol = self.max_symbol
  local table = self.table
  local heads = self.heads
  local sizes = self.sizes
  local stack = self.stack
  local nodes = self.nodes

  local node = {
    symbol;
    n = 1;
    data = data;
  }

  while true do
    local n1 = #stack
    local n2 = #nodes
    local state = stack[n1]
    local action = table[state * max_symbol + symbol]
    if action then
      if action <= max_state then -- shift
        stack[n1 + 1] = action
        nodes[n2 + 1] = node
        return true
      else
        local symbol = heads[action]
        if symbol then -- reduce
          local n = sizes[action]
          for i = n1 - n + 1, n1 do
            stack[i] = nil
          end

          local reduced_nodes = {}
          for i = n2 - n + 1, n2 do
            reduced_nodes[#reduced_nodes + 1] = nodes[i]
            nodes[i] = nil
          end

          local node = {
            symbol;
            n = n + 1;
          }
          for i = 1, n do
            node[i + 1] = reduced_nodes[i]
          end

          local n1 = #stack
          local n2 = #nodes
          local state = stack[n1]
          stack[n1 + 1] = table[state * max_symbol + symbol]
          nodes[n2 + 1] = node
        else -- accept
          stack[n1] = nil
          local node = nodes[n2]
          nodes[n2] = nil
          return node
        end
      end
    else
      return nil, "parse error", state, node
    end
  end
end

return setmetatable(class, {
  __call = function (_, data)
    return setmetatable({
      symbol_names = data.symbol_names;
      max_state = data.max_state;
      max_symbol = data.max_symbol;
      table = data.table;
      heads = data.heads;
      sizes = data.sizes;
      stack = { 1 }; -- start state
      nodes = {};
    }, metatable)
  end
})
