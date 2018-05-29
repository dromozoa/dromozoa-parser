-- Copyright (C) 2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local epsilon_closure = require "dromozoa.parser.regexp.epsilon_closure"

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

return function (this)
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
