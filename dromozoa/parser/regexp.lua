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

local function set_to_key(set)
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
      epsilon_closure[u] = true
      stack[n] = nil
      local v = nfa.epsilons1[u]
      if v ~= nil then
        if not color[v] then
          stack[n] = v
          color[v] = true
          n = n + 1
        end
        local v = nfa.epsilons2[u]
        if v ~= nil and not color[v] then
          stack[n] = v
          color[v] = true
        end
      end
    end
    epsilon_closures[state] = epsilon_closure
  end

  local map = {}
  local s = set_to_key(epsilon_closures[nfa.start_state])
  insert(map, s, 1)

  local stack = { s }
  local dfa = 1

  local transitions = {}
  for i = 0, 255 do
    transitions[i] = {}
  end

  local dfa_accepts = {}
  if epsilon_closures[nfa.start_state][nfa.accept_state] then
    dfa_accepts[1] = true
  end

  while true do
    local n = #stack
    local u = stack[n]
    if u == nil then
      break
    end
    stack[n] = nil
    local from = find(map, u)
    for char = 0, 255 do
      local to_states = {}
      for i = 1, #u do
        local state = u[i]
        local condition = nfa.conditions[state]
        if condition and condition[char] then
          local to_closure = epsilon_closures[nfa.transitions[state]]
          for k in pairs(to_closure) do
            to_states[k] = true
          end
        end
      end
      local to = set_to_key(to_states)
      if #to > 0 then
        local to_state = find(map, to)
        if to_state == nil then
          dfa = dfa + 1
          to_state = dfa
          insert(map, to, to_state)
          stack[#stack + 1] = to
          if to_states[nfa.accept_state] then
            dfa_accepts[to_state] = true
          end
        end
        print(from, table.concat(u, ","), to_state, table.concat(to, ","))
        transitions[char][from] = to_state
      end
    end
  end

  return epsilon_closures, transitions, dfa, dfa_accepts
end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), class.metatable)
  end;
})
