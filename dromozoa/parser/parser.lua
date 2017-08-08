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

local compile = require "dromozoa.parser.parser.compile"
local error_message = require "dromozoa.parser.error_message"
local write_graphviz = require "dromozoa.parser.parser.write_graphviz"

local class = {}
local metatable = {
  __index = class;
}
class.metatable = metatable

function class:compile(out)
  if type(out) == "string" then
    compile(self, assert(io.open(out, "w"))):close()
  else
    return compile(self, out)
  end
end

function class:write_graphviz(out, tree)
  if type(out) == "string" then
    write_graphviz(self, assert(io.open(out, "w")), tree):close()
  else
    return write_graphviz(self, out, tree)
  end
end

function metatable:__call(symbol, s, file, p, i, j, rs, ri, rj)
  local max_state = self.max_state
  local max_terminal_symbol = self.max_terminal_symbol
  local actions = self.actions
  local gotos = self.gotos
  local heads = self.heads
  local sizes = self.sizes
  local reduce_to_semantic_actions = self.reduce_to_semantic_actions
  local stack = self.stack
  local nodes = self.nodes

  local node = {
    [0] = symbol;
    n = 0;
    p = p;
    i = i;
    j = j;
    rs = rs;
    ri = ri;
    rj = rj;
  }

  while true do
    local n1 = #stack
    local n2 = #nodes
    local state = stack[n1]

    local action
    if symbol <= max_terminal_symbol then
      action = actions[state][symbol]
    else
      action = gotos[state][symbol - max_terminal_symbol]
    end

    if action then
      if action <= max_state then -- shift
        stack[n1 + 1] = action
        nodes[n2 + 1] = node
        return true
      else
        local head = heads[action]
        if head then -- reduce
          local n = sizes[action]
          for i = n1 - n + 1, n1 do
            stack[i] = nil
          end

          local reduced_nodes = {}
          for i = n2 - n + 1, n2 do
            reduced_nodes[#reduced_nodes + 1] = nodes[i]
            nodes[i] = nil
          end

          local node
          local semantic_actions = reduce_to_semantic_actions[action]
          if semantic_actions[1] then
            for i = 1, #semantic_actions do
              local semantic_action = semantic_actions[1]
              local code = semantic_action[1]
              if code == 1 then -- list
                node = reduced_nodes[1]
                local m = node.n
                for i = 2, n do
                  m = m + 1
                  node[m] = reduced_nodes[i]
                end
                node.n = m
              end
            end
          else
            node = {
              [0] = head;
              n = n;
            }
            for i = 1, n do
              node[i] = reduced_nodes[i]
            end
          end

          local n1 = #stack
          local n2 = #nodes
          local state = stack[n1]
          assert(head > max_terminal_symbol)
          stack[n1 + 1] = gotos[state][head - max_terminal_symbol]
          nodes[n2 + 1] = node
        else -- accept
          stack[n1] = nil
          local accepted_node = nodes[n2]
          nodes[n2] = nil
          return accepted_node
        end
      end
    else
      return nil, error_message("parser error", s, i, file)
    end
  end
end

return setmetatable(class, {
  __call = function (_, data)
    return setmetatable({
      symbol_names = data.symbol_names;
      symbol_table = data.symbol_table;
      max_state = data.max_state;
      max_terminal_symbol = data.max_terminal_symbol;
      actions = data.actions;
      gotos = data.gotos;
      heads = data.heads;
      sizes = data.sizes;
      reduce_to_semantic_actions = data.reduce_to_semantic_actions;
      stack = { 1 }; -- start state
      nodes = {};
    }, metatable)
  end
})
