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
  local k = key[n]
  local v = map[k]
  if v then
    return v, false
  else
    local v = value + 1
    map[k] = v
    return v, true
  end
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

local function visit(this, that, epsilon_closures, maps, max_state, useq)
  local transitions = this.transitions
  local accept_states = this.accept_states
  local new_transitions = that.transitions
  local new_accept_states = that.accept_states
  local u = max_state

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
      local v, inserted = insert(maps, vseq, max_state)
      new_transitions[byte][u] = v
      if inserted then
        new_accept_states[v] = merge_accept_state(accept_states, vset)
        max_state = visit(this, that, epsilon_closures, maps, v, vseq)
      end
    end
  end

  return max_state
end

return function (this)
  local epsilon_closures = {}
  local maps = {}
  local uset = epsilon_closure(this, epsilon_closures, this.start_state)
  local useq = set_to_seq(uset)
  insert(maps, useq, 0)

  local new_transitions = {}
  for byte = 0, 255 do
    new_transitions[byte] = {}
  end
  local that = {
    transitions = new_transitions;
    accept_states = {
      merge_accept_state(this.accept_states, uset);
    };
    start_state = 1;
  }

  that.max_state = visit(this, that, epsilon_closures, maps, 1, useq)

  return that
end
