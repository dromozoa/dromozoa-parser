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

local tag_names = {
  "[",
  "concat",
  "|",
  "*",
  "?",
}

local tag_table = {}
for i = 1, #tag_names do
  tag_table[tag_names[i]] = i
end

local max_terminal_tag = 1

local class = {
  tag_names = tag_names;
  tag_table = tag_table;
  max_terminal_tag = max_terminal_tag;
}

local function dfs_finish_edge(u, fn)
  local tag = u[1]
  if tag > max_terminal_tag then
    for i = 2, #u do
      local v = u[i]
      dfs_finish_edge(v, fn)
      fn(u, v)
    end
  end
end

local function node_to_nfa(node, self)
  local tag = node[1]
  local a = node[2]
  local b = node[3]
  if tag > max_terminal_tag then
    node_to_nfa(a, self)
    if b then
      node_to_nfa(b, self)
    end
  end
  print(tag_names[tag])
end

function class.new(root)
  return {}
end

function class.tree_to_nfa(node)
  local n = 0
  local transitions = {}
  for i = -2, 255 do
    transitions[i] = {}
  end

  -- dfs finish vertex
  local stack1 = { node }
  local stack2 = {}

  while true do
    local n1 = #stack1
    local n2 = #stack2
    local node = stack1[n1]
    if node == nil then
      break
    end
    local tag = node[1]
    if node == stack2[n2] then
      stack1[n1] = nil
      stack2[n2] = nil

      -- process node
      local a = node[2]
      local b = node[3]
      if tag == 1 then
        n = n + 1
        local u = n
        n = n + 1
        local v = n
        node.u = u
        node.v = v
        local set = node[2]
        for i = 0, 255 do
          if a[i] then
            transitions[i][u] = v
          end
        end
      elseif tag == 2 then
        assert(transitions[-1][a.v] == nil)
        transitions[-1][a.v] = b.u
        node.u = a.u
        node.v = b.v
      elseif tag == 3 then
        n = n + 1
        local u = n
        n = n + 1
        local v = n
        assert(b.v)
        assert(transitions[-1][u] == nil)
        assert(transitions[-2][u] == nil)
        assert(transitions[-1][a.v] == nil)
        assert(transitions[-1][b.v] == nil)
        transitions[-1][u] = a.u
        transitions[-2][u] = b.u
        transitions[-1][a.v] = v
        transitions[-1][b.v] = v
        node.u = u
        node.v = v
      elseif tag == 4 then
        n = n + 1
        local u = n
        n = n + 1
        local v = n
        local au = a.u
        local av = a.v
        assert(transitions[-1][u] == nil)
        assert(transitions[-2][u] == nil)
        assert(transitions[-1][a.v] == nil)
        assert(transitions[-2][a.v] == nil)
        transitions[-1][u] = au
        transitions[-2][u] = v
        transitions[-1][av] = v
        transitions[-2][av] = au
        node.u = u
        node.v = v
      elseif tag == 5 then
        n = n + 1
        local u = n
        n = n + 1
        local v = n
        local au = a.u
        local av = a.v
        assert(transitions[-1][u] == nil)
        assert(transitions[-2][u] == nil)
        assert(transitions[-1][a.v] == nil)
        transitions[-1][u] = au
        transitions[-2][u] = v
        transitions[-1][av] = v
        node.u = u
        node.v = v
      end
    else
      if tag > max_terminal_tag then
        local a = node[2]
        local b = node[3]
        if b then
          stack1[n1 + 1] = b
          stack1[n1 + 2] = a
        else
          stack1[n1 + 1] = a
        end
      end
      stack2[n2 + 1] = node
    end
  end

  return transitions, n
end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), class.metatable)
  end;
})
