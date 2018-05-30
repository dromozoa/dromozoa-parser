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

local function build_reverse_transitions(transitions, reverse_transitions, color, u)
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
        color[v] = true
        build_reverse_transitions(transitions, reverse_transitions, color, v)
      end
    end
  end
end

local function build_reverse_color(reverse_transitions, color, color_max, u)
  local reverse_transition = reverse_transitions[u]
  if reverse_transition then
    for v in pairs(reverse_transition) do
      if not color[v] then
        color[v] = true
        if color_max < v then
          color_max = v
        end
        color_max = build_reverse_color(reverse_transitions, color, color_max, v)
      end
    end
  end
  return color_max
end

return function (this)
  local transitions = this.transitions
  local start_state = this.start_state
  local accept_states = this.accept_states

  local reverse_transitions = {}
  build_reverse_transitions(transitions, reverse_transitions, { [start_state] = true }, start_state)

  local color = {}
  local color_max
  for u in pairs(accept_states) do
    color[u] = true
    if not color_max or color_max < u then
      color_max = u
    end
    color_max = build_reverse_color(reverse_transitions, color, color_max, u)
  end

  local accept_partitions = {}
  local nonaccept_partition
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
        if nonaccept_partition then
          nonaccept_partition[#nonaccept_partition + 1] = u
        else
          nonaccept_partition = { u }
        end
      end
    end
  end

  local partitions = {}
  local partition_table = {}
  local n = 0
  for _, partition in pairs(accept_partitions) do
    n = n + 1
    partitions[n] = partition
  end
  if nonaccept_partition then
    n = n + 1
    partitions[n] = nonaccept_partition
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
