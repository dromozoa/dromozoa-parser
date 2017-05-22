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

local dumper = require "dromozoa.commons.dumper"
local equal = require "dromozoa.commons.equal"

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

function class.new(root)
  return {}
end

function class.tree_to_nfa(root)
  local n = 0
  local epsilons1 = {}
  local epsilons2 = {}
  local conditions = {}
  local transitions = {}

  local stack1 = { root }
  local stack2 = {}

  while true do
    local n1 = #stack1
    local n2 = #stack2
    local node = stack1[n1]
    if node == nil then
      break
    end
    local tag = node[1]
    local a = node[2]
    local b = node[3]
    if node == stack2[n2] then
      stack1[n1] = nil
      stack2[n2] = nil
      -- finish vertex
      if tag == 2 then -- "concat"
        node.u = a.u
        node.v = b.v
        epsilons1[a.v] = b.u
      else
        n = n + 1
        local u = n
        node.u = u
        n = n + 1
        local v = n
        node.v = v
        if tag == 1 then -- "["
          conditions[u] = a
          transitions[u] = v
        elseif tag == 3 then -- "|"
          epsilons1[u] = a.u
          epsilons2[u] = b.u
          epsilons1[a.v] = v
          epsilons1[b.v] = v
        else -- "*" or "?"
          local au = a.u
          local av = a.v
          epsilons1[u] = au
          epsilons2[u] = v
          epsilons1[av] = v
          if tag == 4 then -- "*"
            epsilons2[av] = au
          end
        end
      end
    else
      if tag > max_terminal_tag then
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

  return {
    epsilons1 = epsilons1;
    epsilons2 = epsilons2;
    conditions = conditions;
    transitions = transitions;
    max_state = n;
    start_state = root.u;
    accept_state = root.v;
  }
end

local function set_to_seq(set)
  local n = 0
  local key = {}
  for k in pairs(set) do
    n = n + 1
    key[n] = k
  end
  table.sort(key)
  return key
end

local function find(map, key)
  for i = 1, #key do
    local k = key[i]
    map = map[k]
    if map == nil then
      return
    end
  end
  return map[0]
end

local function insert(map, key, value)
  for i = 1, #key do
    local k = key[i]
    local m = map[k]
    if m == nil then
      m = {}
      map[k] = m
    end
    map = m
  end
  map[0] = value
end

function class.nfa_to_dfa(nfa)
  local nfa_epsilons1 = nfa.epsilons1
  local nfa_epsilons2 = nfa.epsilons2
  local nfa_conditions = nfa.conditions
  local nfa_transitions = nfa.transitions
  local nfa_max_state = nfa.max_state
  local nfa_start_state = nfa.start_state
  local nfa_accept_state = nfa.accept_state

  local epsilon_closures = {}
  for state = 1, nfa_max_state do
    local stack = { state }
    local color = { [state] = true }
    local epsilon_closure = {}
    while true do
      local n = #stack
      local u = stack[n]
      if u == nil then
        break
      end
      stack[n] = nil
      epsilon_closure[u] = true
      local v = nfa_epsilons1[u]
      if v then
        if not color[v] then
          stack[n] = v
          color[v] = true
          n = n + 1
        end
        local v = nfa_epsilons2[u]
        if v and not color[v] then
          stack[n] = v
          color[v] = true
        end
      end
    end
    epsilon_closures[state] = epsilon_closure
  end

  local map = {}

  local n = 1
  local set = epsilon_closures[nfa_start_state]
  local seq = set_to_seq(set)
  insert(map, seq, n)

  local transitions = {}
  for i = 0, 255 do
    transitions[i] = {}
  end

  local accept_states = {}
  if set[nfa_accept_state] then
    accept_states[n] = true
  end

  local stack = { seq }

  while true do
    local m = #stack
    local useq = stack[m]
    if useq == nil then
      break
    end
    stack[m] = nil
    local u = find(map, useq)
    for i = 0, 255 do
      local vset = {}
      for j = 1, #useq do
        local w = useq[j]
        local condition = nfa_conditions[w]
        if condition and condition[i] then
          for k in pairs(epsilon_closures[nfa_transitions[w]]) do
            vset[k] = true
          end
        end
      end
      local vseq = set_to_seq(vset)
      if #vseq > 0 then
        local v = find(map, vseq)
        if v == nil then
          n = n + 1
          v = n
          insert(map, vseq, v)
          stack[m] = vseq
          m = m + 1
          if vset[nfa_accept_state] then
            accept_states[v] = true
          end
        end
        transitions[i][u] = v
      end
    end
  end

  return {
    transitions = transitions;
    max_state = n;
    start_state = 1;
    accept_states = accept_states;
  }, epsilon_closures
end

function class.minimize_dfa(dfa)
  local transitions = dfa.transitions
  local max_state = dfa.max_state
  local accept_states = dfa.accept_states

  local partitions = { {} }
  local partition_table = {}

  for i = 1, max_state do
    if accept_states[i] then
      local partition = partitions[1]
      partition[#partition + 1] = i
      partition_table[i] = 1
    else
      local partition = partitions[2]
      if partition == nil then
        partition = {}
        partitions[2] = partition
      end
      partition[#partition + 1] = i
      partition_table[i] = 2
    end
  end

  print("partitions", dumper.encode(partitions))

  repeat
    local new_partitions = {}
    local new_partition_table = {}

    for i = 1, #partitions do
      local partition = partitions[i]
      for i = 1, #partition do
        local x = partition[i]
        for j = 1, i - 1 do
          local y = partition[j]
          local same_group = true
          for char = 0, 255 do
            local tx = transitions[char][x]
            local ty = transitions[char][y]
            if partition_table[tx] ~= partition_table[ty] then
              same_group = false
              break
            end
          end
          -- x and y is same group
          -- print(same_group, x, y)
          if same_group then
            local gx = new_partition_table[x]
            local gy = new_partition_table[y]
            if gx ~= nil then
              -- assert(gy == nil, ("x,y,gx,gy=%d,%d,%d,%d"):format(x, y, gx, gy))
              if gy == nil then
                local partition = new_partitions[gx]
                partition[#partition + 1] = y
                new_partition_table[y] = gx
              else
                assert(gx == gy)
              end
            elseif gy ~= nil then
              assert(gx == nil)
              local partition = new_partitions[gy]
              partition[#partition + 1] = x
              new_partition_table[x] = gy
            else
              local g = #new_partitions + 1
              new_partitions[g] = { x, y }
              new_partition_table[x] = g
              new_partition_table[y] = g
            end
          end
        end
      end

      for i = 1, #partition do
        local x = partition[i]
        local gx = new_partition_table[x]
        if gx == nil then
          local g = #new_partitions + 1
          new_partitions[g] = { x }
          new_partition_table[x] = g
        end
      end

    end

    local done = #partitions == #new_partitions
    partitions = new_partitions
    partition_table = new_partition_table

    print("partitions", dumper.encode(partitions))
  until done

  local new_transitions = {}
  for char = 0, 255 do
    new_transitions[char] = {}
  end
  local new_accept_states = {}

  local n = #partitions
  for i = 1, n do
    local p = partitions[i]
    local j = partition_table[p[1]]
    for k = 2, #p do
      assert(partition_table[p[k]] == j)
    end
    for char = 0, 255 do
      local t = transitions[char][p[1]]
      if t then
        new_transitions[char][i] = partition_table[t]
      end
    end
    if accept_states[p[1]] then
      new_accept_states[i] = true
    end
  end
  return {
    transitions = new_transitions,
    max_state = n;
    start_state = partition_table[start_state];
    accept_states = new_accept_states;
  }, partitions
end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), class.metatable)
  end;
})
