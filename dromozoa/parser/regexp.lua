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

local function set_to_seq(set)
  local key = {}
  for k in pairs(set) do
    key[#key + 1] = k
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

local function merge_accept_state(accept_states, set)
  local result
  for k in pairs(set) do
    local accept = accept_states[k]
    if accept then
      if result == nil or result > accept then
        result = accept
      end
    end
  end
  return result
end

local class = {}

function class.tree_to_nfa(root, accept)
  if accept == nil then
    accept = 1
  end

  local max_state = 0
  local epsilons1 = {}
  local epsilons2 = {}
  local epsilons = { epsilons1, epsilons2 }
  local transitions = {}
  for char = 0, 255 do
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
    local code = node[1]
    local a = node[2]
    local b = node[3]
    if node == stack2[n2] then
      stack1[n1] = nil
      stack2[n2] = nil
      if code == 2 then -- concatenation
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
        if code == 1 then -- character class
          for char in pairs(a) do
            transitions[char][u] = v
          end
        elseif code == 3 then -- union
          epsilons1[u] = a.u
          epsilons2[u] = b.u
          epsilons1[a.v] = v
          epsilons1[b.v] = v
        elseif code == 6 then -- difference
          -- [TODO] コードをきれいにする
          local dfa1 = class.minimize(class.nfa_to_dfa({
            max_state = max_state;
            epsilons = epsilons;
            transitions = transitions;
            start_state = a.u;
            accept_states = { [a.v] = accept };
          }))
          local dfa2 = class.minimize(class.nfa_to_dfa({
            max_state = max_state;
            epsilons = epsilons;
            transitions = transitions;
            start_state = b.u;
            accept_states = { [b.v] = accept };
          }))
          local dfa = class.difference(dfa1, dfa2)
          local dfa = class.minimize(dfa)

          local this, that = class.merge({
            max_state = max_state;
            epsilons = epsilons;
            transitions = transitions;
            start_state = u;
            accept_states = { [v] = accept };
          }, dfa)

          max_state = this.max_state

          epsilons1[u] = that.start_state
          for w in pairs(that.accept_states) do
            epsilons1[w] = v
          end

        else -- 0 or more repetition / optional
          local au = a.u
          local av = a.v
          epsilons1[u] = au
          epsilons2[u] = v
          epsilons1[av] = v
          if code == 4 then -- 0 or more repetition
            epsilons2[av] = au
          end
        end
      end
    else
      if code > 1 then
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
    epsilons = epsilons;
    transitions = transitions;
    start_state = root.u;
    accept_states = { [root.v] = accept };
  }
end

function class.nfa_to_dfa(nfa)
  local epsilons = nfa.epsilons
  local epsilons1 = epsilons[1]
  local epsilons2 = epsilons[2]
  local transitions = nfa.transitions
  local accept_states = nfa.accept_states

  -- [TODO] 効率化できるか？
  -- [TODO] nfa.max_stateに依存しないようにする
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
  for char = 0, 255 do
    new_transitions[char] = {}
  end
  local new_accept_states = {
    [max_state] = merge_accept_state(accept_states, uset);
  }

  local stack = { useq }
  while true do
    local n = #stack
    local useq = stack[n]
    if useq == nil then
      break
    end
    stack[n] = nil
    local u = find(maps, useq)
    for char = 0, 255 do
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
          new_accept_states[v] = merge_accept_state(accept_states, vset)
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

function class.minimize(this)
  local transitions = this.transitions
  local accept_states = this.accept_states

  -- [TODO] accept_statesに到達しない状態を探す

  local accept_partitions = {}
  local partition
  for state = 1, this.max_state do
    local accept = accept_states[state]
    if accept then
      local partition = accept_partitions[accept]
      if partition == nil then
        partition = {}
        accept_partitions[accept] = partition
      end
      partition[#partition + 1] = state
    else
      if partition == nil then
        partition = {}
      end
      partition[#partition + 1] = state
    end
  end
  local partitions = {}
  for _, partition in pairs(accept_partitions) do
    partitions[#partitions + 1] = partition
  end
  if partition then
    partitions[#partitions + 1] = partition
  end
  local partition_table = {}
  for i = 1, #partitions do
    local partition = partitions[i]
    for j = 1, #partition do
      partition_table[partition[j]] = i
    end
  end

  while true do
    local new_partitions = {}
    local new_partition_table = {}
    for i = 1, #partitions do
      local partition = partitions[i]
      local n = #partition
      for i = 1, n do
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
          if same_group then
            local gx = new_partition_table[x]
            local gy = new_partition_table[y]
            if gx then
              if gy == nil then
                local partition = new_partitions[gx]
                partition[#partition + 1] = y
                new_partition_table[y] = gx
              end
            elseif gy then
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
        if new_partition_table[x] == nil then
          local g = #new_partitions + 1
          new_partitions[g] = { x }
          new_partition_table[x] = g
        end
      end
    end
    if #partitions == #new_partitions then
      break
    end
    partitions = new_partitions
    partition_table = new_partition_table
  end

  local max_state = #partitions
  local new_transitions = {}
  for char = 0, 255 do
    new_transitions[char] = {}
  end
  local new_accept_states = {}

  for i = 1, max_state do
    local partition = partitions[i]
    local state = partition[1]
    for char = 0, 255 do
      local transition = transitions[char][state]
      if transition then
        new_transitions[char][i] = partition_table[transition]
      end
    end
    new_accept_states[i] = accept_states[state]
  end

  return {
    max_state = max_state;
    transitions = new_transitions,
    start_state = partition_table[this.start_state];
    accept_states = new_accept_states;
  }, partitions
end

function class.merge(this, that)
  local max_state = this.max_state
  local epsilons = this.epsilons
  local epsilons1
  local epsilons2
  if epsilons == nil then
    epsilons1 = {}
    epsilons2 = {}
    epsilons = { epsilons1, epsilons2 }
    this.epsilons = epsilons
  else
    epsilons1 = epsilons[1]
    epsilons2 = epsilons[2]
  end
  local transitions = this.transitions

  local that_epsilons = that.epsilons
  if that_epsilons then
    for from_state, to_state in pairs(that_epsilons[1]) do
      epsilons1[from_state + max_state] = to_state + max_state
    end
    for from_state, to_state in pairs(that_epsilons[2]) do
      epsilons2[from_state + max_state] = to_state + max_state
    end
  end

  local that_transitions = that.transitions
  for char = 0, 255 do
    local transition = transitions[char]
    for from_state, to_state in pairs(that_transitions[char]) do
      transition[from_state + max_state] = to_state + max_state
    end
  end

  local accept_states = {}
  for state, accept in pairs(that.accept_states) do
    accept_states[state + max_state] = accept
  end

  local start_state = that.start_state + max_state

  local max_state = max_state + that.max_state
  this.max_state = max_state

  return this, {
    max_state = max_state;
    epsilons = epsilons;
    transitions = transitions;
    start_state = start_state;
    accept_states = accept_states
  }
end

function class.union(this, that)
  local this, that = class.merge(this, that)

  local max_state = this.max_state + 1
  local epsilons = this.epsilons
  local accept_states = this.accept_states

  epsilons[1][max_state] = this.start_state
  epsilons[2][max_state] = that.start_state

  for state, accept in pairs(that.accept_states) do
    accept_states[state] = accept
  end

  this.max_state = max_state
  this.start_state = max_state
  return this
end

function class.difference(this, that)
  local transitions = {}
  for char = 0, 255 do
    transitions[char] = {}
  end

  local this_max_state = this.max_state
  local that_max_state = that.max_state
  local n = this_max_state + 1

  local this_trantions = this.transitions
  local that_trantions = that.transitions

  for i = 0, this_max_state do
    for j = 0, that_max_state do
      local u = i + n * j
      if u ~= 0 then
        local transition = {}
        for char = 0, 255 do
          local tx = this_trantions[char][i]
          local ty = that_trantions[char][j]
          if tx == nil then
            tx = 0
          end
          if ty == nil then
            ty = 0
          end
          local v = tx + n * ty
          if v ~= 0 then
            transitions[char][u] = v
          end
        end
      end
    end
  end

  local accept_states = {}
  local that_accept_states = that.accept_states

  for i, accept in pairs(this.accept_states) do
    for j = 1, that_max_state do
      if that_accept_states[j] == nil then
        local u = i + n * j
        accept_states[u] = accept
      end
    end
  end

  return {
    max_state = this_max_state + n * that_max_state;
    transitions = transitions;
    start_state = this.start_state + n * that.start_state;
    accept_states = accept_states;
  }
end

return class
