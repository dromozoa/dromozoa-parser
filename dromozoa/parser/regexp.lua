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
local min_char = 0
local max_char = 255

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

local function find(maps, key)
  local n = #key
  local map = maps[n]
  if map == nil then
    return
  end
  for i = 1, n - 1 do
    map = map[key[i]]
    if map == nil then
      return
    end
  end
  return map[key[n]]
end

local function insert(maps, key, value)
  local n = #key
  local map = maps[n]
  if map == nil then
    map = {}
    maps[n] = map
  end
  for i = 1, n - 1 do
    local k = key[i]
    local m = map[k]
    if m == nil then
      m = {}
      map[k] = m
    end
    map = m
  end
  map[key[n]] = value
end

local class = {
  tag_names = tag_names;
  tag_table = tag_table;
  max_terminal_tag = max_terminal_tag;
}

function class.new(root)
  return {}
end

function class.tree_to_nfa(root)
  local max_state = 0
  local epsilons1 = {}
  local epsilons2 = {}
  local transitions = {}
  for char = min_char, max_char do
    transitions[char] = {}
  end

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
      if tag == 2 then -- "concat"
        node.u = a.u
        node.v = b.v
        epsilons1[a.v] = b.u
      else
        max_state = max_state + 1
        local u = max_state
        node.u = u
        max_state = max_state + 1
        local v = max_state
        node.v = v
        if tag == 1 then -- "["
          for char in pairs(a) do
            transitions[char][u] = v
          end
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
    max_state = max_state;
    epsilons = { epsilons1, epsilons2 };
    transitions = transitions;
    start_state = root.u;
    accept_states = { [root.v] = true };
  }
end

function class.nfa_to_dfa(nfa)
  local epsilons = nfa.epsilons
  local epsilons1 = epsilons[1]
  local epsilons2 = epsilons[2]
  local transitions = nfa.transitions
  local accept_states = nfa.accept_states

  local epsilon_closures = {}
  for state = 1, nfa.max_state do
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
      local v = epsilons1[u]
      if v then
        if not color[v] then
          stack[n] = v
          color[v] = true
          n = n + 1
        end
        local v = epsilons2[u]
        if v and not color[v] then
          stack[n] = v
          color[v] = true
        end
      end
    end
    epsilon_closures[state] = epsilon_closure
  end

  local max_state = 1

  local uset = epsilon_closures[nfa.start_state]
  local useq = set_to_seq(uset)
  local maps = {}
  insert(maps, useq, max_state)

  local new_transitions = {}
  for i = min_char, max_char do
    new_transitions[i] = {}
  end

  local new_accept_states = {}
  for k in pairs(uset) do
    if accept_states[k] then
      new_accept_states[max_state] = true
      break
    end
  end

  local stack = { useq }

  while true do
    local n = #stack
    local useq = stack[n]
    if useq == nil then
      break
    end
    stack[n] = nil
    local u = find(maps, useq)
    for char = min_char, max_char do
      local vset
      for i = 1, #useq do
        local transition = transitions[char][useq[i]]
        if transition then
          for k in pairs(epsilon_closures[transition]) do
            if vset == nil then
              vset = {}
            end
            vset[k] = true
          end
        end
      end
      if vset then
        local vseq = set_to_seq(vset)
        local v = find(maps, vseq)
        if v == nil then
          max_state = max_state + 1
          v = max_state
          insert(maps, vseq, v)
          stack[n] = vseq
          n = n + 1
          for k in pairs(vset) do
            if accept_states[k] then
              new_accept_states[v] = true
              break
            end
          end
        end
        new_transitions[char][u] = v
      end
    end
  end

  return {
    max_state = max_state;
    transitions = new_transitions;
    start_state = 1;
    accept_states = new_accept_states;
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

  repeat
    local new_partitions = {}
    local new_partition_table = {}

    for i = 1, #partitions do
      local partition = partitions[i]
      local n = #partition
      for i = 1, n - 1 do
        local x = partition[i]
        for j = i + 1, n do
          local y = partition[j]
          local same_group = true
          for char = min_char, max_char do
            local tx = transitions[char][x]
            local ty = transitions[char][y]
            if partition_table[tx] ~= partition_table[ty] then
              same_group = false
              break
            end
          end
          if same_group then
            local gx = new_partition_table[x]
            local gy = new_partition_table[y]
            if gx ~= nil then
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
  until done

  local new_transitions = {}
  for char = min_char, max_char do
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
    for char = min_char, max_char do
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
