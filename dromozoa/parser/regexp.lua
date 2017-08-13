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

local write_graphviz = require "dromozoa.parser.regexp.write_graphviz"

local function set_to_seq(set)
  local seq = {}
  for u in pairs(set) do
    seq[#seq + 1] = u
  end
  table.sort(seq)
  return seq
end

local function find(maps, key)
  local n = #key
  local map = maps[n]
  if not map then
    return
  end
  for i = 1, n - 1 do
    map = map[key[i]]
    if not map then
      return
    end
  end
  return map[key[n]]
end

local function insert(maps, key, value)
  local n = #key
  local map = maps[n]
  if not map then
    map = {}
    maps[n] = map
  end
  for i = 1, n - 1 do
    local k = key[i]
    local m = map[k]
    if not m then
      m = {}
      map[k] = m
    end
    map = m
  end
  map[key[n]] = value
end

local function epsilon_closure(this, epsilon_closures, u)
  local epsilon_closure = epsilon_closures[u]
  if not epsilon_closure then
    epsilon_closure = {}
    epsilon_closures[u] = epsilon_closure

    local epsilons = this.epsilons
    local epsilons1 = epsilons[1]
    local epsilons2 = epsilons[2]

    local stack = { u }
    local color = { [u] = true }
    while true do
      local n = #stack
      local u = stack[n]
      if not u then
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
  end
  return epsilon_closure
end

local function merge_accept_state(accept_states, set)
  local result
  for u in pairs(set) do
    local accept = accept_states[u]
    if accept and (not result or result > accept) then
      result = accept
    end
  end
  return result
end

local function nfa_to_dfa(this)
  local transitions = this.transitions
  local accept_states = this.accept_states

  local max_state = 1
  local epsilon_closures = {}
  local maps = {}

  local uset = epsilon_closure(this, epsilon_closures, this.start_state)
  local useq = set_to_seq(uset)
  insert(maps, useq, max_state)

  local new_transitions = {}
  for byte = 0, 255 do
    new_transitions[byte] = {}
  end
  local new_accept_states = {
    [max_state] = merge_accept_state(accept_states, uset);
  }

  local stack = { useq }
  while true do
    local n = #stack
    local useq = stack[n]
    if not useq then
      break
    end
    stack[n] = nil
    local u = find(maps, useq)
    for byte = 0, 255 do
      local vset
      for i = 1, #useq do
        local x = transitions[byte][useq[i]]
        if x then
          for y in pairs(epsilon_closure(this, epsilon_closures, x)) do
            if vset then
              vset[y] = true
            else
              vset = { [y] = true }
            end
          end
        end
      end
      if vset then
        local vseq = set_to_seq(vset)
        local v = find(maps, vseq)
        if v then
          new_transitions[byte][u] = v
        else
          max_state = max_state + 1
          insert(maps, vseq, max_state)
          stack[#stack + 1] = vseq
          new_accept_states[max_state] = merge_accept_state(accept_states, vset)
          new_transitions[byte][u] = max_state
        end
      end
    end
  end

  return {
    max_state = max_state;
    transitions = new_transitions;
    start_state = 1;
    accept_states = new_accept_states;
  }
end

local function minimize(this)
  local transitions = this.transitions
  local start_state = this.start_state
  local accept_states = this.accept_states

  local reverse_transitions = {}

  local stack = { start_state }
  local color = { [start_state] = true }
  while true do
    local n = #stack
    local u = stack[n]
    if not u then
      break
    end
    stack[n] = nil
    for byte = 0, 255 do
      local v = transitions[byte][u]
      if v and u ~= v then
        local reverse_transition = reverse_transitions[v]
        if reverse_transition then
          reverse_transition[u] = true
        else
          reverse_transitions[v] = { [u] = true }
        end
        if not color[v] then
          stack[#stack + 1] = v
          color[v] = true
        end
      end
    end
  end

  local stack = {}
  local color = {}
  local color_max
  for u in pairs(accept_states) do
    stack[#stack + 1] = u
    color[u] = true
    if not color_max or color_max < u then
      color_max = u
    end
  end
  while true do
    local n = #stack
    local u = stack[n]
    if not u then
      break
    end
    stack[n] = nil
    local reverse_transition = reverse_transitions[u]
    if reverse_transition then
      for v in pairs(reverse_transition) do
        if not color[v] then
          stack[#stack + 1] = v
          color[v] = true
          if not color_max or color_max < v then
            color_max = v
          end
        end
      end
    end
  end

  local accept_partitions = {}
  local partition
  for u = 1, color_max do
    if color[u] then
      local accept = accept_states[u]
      if accept then
        local partition = accept_partitions[accept]
        if partition then
          partition[#partition + 1] = u
        else
          accept_partitions[accept] = { u }
        end
      else
        if partition then
          partition[#partition + 1] = u
        else
          partition = { u }
        end
      end
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
      for i = 1, #partition do
        local x = partition[i]
        for j = 1, i - 1 do
          local y = partition[j]
          local same_partition = true
          for byte = 0, 255 do
            if partition_table[transitions[byte][x]] ~= partition_table[transitions[byte][y]] then
              same_partition = false
              break
            end
          end
          if same_partition then
            local px = new_partition_table[x]
            local py = new_partition_table[y]
            if px then
              if not py then
                local new_partition = new_partitions[px]
                new_partition[#new_partition + 1] = y
                new_partition_table[y] = px
              end
            elseif py then
              local new_partition = new_partitions[py]
              new_partition[#new_partition + 1] = x
              new_partition_table[x] = py
            else
              local p = #new_partitions + 1
              new_partitions[p] = { x, y }
              new_partition_table[x] = p
              new_partition_table[y] = p
            end
          end
        end
        if not new_partition_table[x] then
          local p = #new_partitions + 1
          new_partitions[p] = { x }
          new_partition_table[x] = p
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
  for byte = 0, 255 do
    new_transitions[byte] = {}
  end
  local new_accept_states = {}

  for i = 1, max_state do
    local partition = partitions[i]
    local u = partition[1]
    for byte = 0, 255 do
      local v = transitions[byte][u]
      if v then
        new_transitions[byte][i] = partition_table[v]
      end
    end
    new_accept_states[i] = accept_states[u]
  end

  return {
    max_state = max_state;
    transitions = new_transitions,
    start_state = partition_table[this.start_state];
    accept_states = new_accept_states;
  }
end

local function merge(this, that)
  local n = this.max_state
  local epsilons = this.epsilons
  local epsilons1
  local epsilons2
  if epsilons then
    epsilons1 = epsilons[1]
    epsilons2 = epsilons[2]
  else
    epsilons1 = {}
    epsilons2 = {}
    epsilons = { epsilons1, epsilons2 }
    this.epsilons = epsilons
  end
  local transitions = this.transitions

  local that_epsilons = that.epsilons
  if that_epsilons then
    for u, v in pairs(that_epsilons[1]) do
      epsilons1[n + u] = n + v
    end
    for u, v in pairs(that_epsilons[2]) do
      epsilons2[n + u] = n + v
    end
  end

  local that_transitions = that.transitions
  for byte = 0, 255 do
    local transition = transitions[byte]
    for u, v in pairs(that_transitions[byte]) do
      transition[n + u] = n + v
    end
  end

  local accept_states = {}
  for u, accept in pairs(that.accept_states) do
    accept_states[n + u] = accept
  end

  local max_state = n + that.max_state
  this.max_state = max_state
  that.max_state = max_state
  that.epsilons = epsilons
  that.transitions = transitions
  that.start_state = n + that.start_state
  that.accept_states = accept_states
  return this, that
end

local function concat(this, that)
  local this, that = merge(this, that)

  local epsilons = this.epsilons
  local epsilons1 = epsilons[1]

  local v = that.start_state
  for u in pairs(this.accept_states) do
    epsilons1[u] = v
  end

  this.accept_states = that.accept_states
  return this
end

local function union(this, that)
  local this, that = merge(this, that)

  local max_state = this.max_state + 1
  local epsilons = this.epsilons
  local accept_states = this.accept_states

  epsilons[1][max_state] = this.start_state
  epsilons[2][max_state] = that.start_state

  for u, accept in pairs(that.accept_states) do
    accept_states[u] = accept
  end

  this.max_state = max_state
  this.start_state = max_state
  return this
end

local function difference(this, that)
  local this_max_state = this.max_state
  local that_max_state = that.max_state
  local this_transitions = this.transitions
  local that_transitions = that.transitions
  local that_accept_states = that.accept_states

  local n = this_max_state + 1

  local transitions = {}
  for byte = 0, 255 do
    transitions[byte] = {}
  end
  local accept_states = {}

  for i = 0, this_max_state do
    for j = 0, that_max_state do
      local u = i + n * j
      if u ~= 0 then
        for byte = 0, 255 do
          local x = this_transitions[byte][i]
          local y = that_transitions[byte][j]
          if not x then
            x = 0
          end
          if not y then
            y = 0
          end
          local v = x + n * y
          if v ~= 0 then
            transitions[byte][u] = v
          end
        end
      end
    end
  end

  for i, accept in pairs(this.accept_states) do
    accept_states[i] = accept
    for j = 1, that_max_state do
      if not that_accept_states[j] then
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

local function tree_to_nfa(root, accept)
  if not accept then
    accept = 1
  end

  local max_state = 0
  local epsilons1 = {}
  local epsilons2 = {}
  local epsilons = { epsilons1, epsilons2 }
  local transitions = {}
  for byte = 0, 255 do
    transitions[byte] = {}
  end

  local stack1 = { root }
  local stack2 = {}
  while true do
    local n1 = #stack1
    local n2 = #stack2
    local node = stack1[n1]
    if not node then
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
          for byte in pairs(a) do
            transitions[byte][u] = v
          end
        elseif code == 3 then -- union
          epsilons1[u] = a.u
          epsilons2[u] = b.u
          epsilons1[a.v] = v
          epsilons1[b.v] = v
        elseif code == 6 then -- difference
          local this = minimize(nfa_to_dfa({
            max_state = max_state;
            epsilons = epsilons;
            transitions = transitions;
            start_state = a.u;
            accept_states = { [a.v] = accept };
          }))
          local that = minimize(nfa_to_dfa({
            max_state = max_state;
            epsilons = epsilons;
            transitions = transitions;
            start_state = b.u;
            accept_states = { [b.v] = accept };
          }))
          local that = minimize(difference(this, that))

          local this, that = merge({
            max_state = max_state;
            epsilons = epsilons;
            transitions = transitions;
            start_state = u;
            accept_states = { [v] = accept };
          }, that)

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

local class = {}
local metatable = {
  __index = class;
}
class.metatable = metatable

function class:nfa_to_dfa()
  return setmetatable(nfa_to_dfa(self), metatable)
end

function class:minimize()
  return setmetatable(minimize(self), metatable)
end

function class:concat(that)
  return concat(self, that)
end

function class:union(that)
  return union(self, that)
end

function class:difference(that)
  return setmetatable(difference(self, that), metatable)
end

function class:write_graphviz(out)
  if type(out) == "string" then
    write_graphviz(self, assert(io.open(out, "w"))):close()
  else
    return write_graphviz(self, out)
  end
end

return setmetatable(class, {
  __call = function (_, root, accept)
    return setmetatable(tree_to_nfa(root, accept), metatable)
  end;
})
