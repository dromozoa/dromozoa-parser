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

local keys = require "dromozoa.commons.keys"
local dumper = require "dromozoa.commons.dumper"
local unpack = require "dromozoa.commons.unpack"
local regexp = require "dromozoa.parser.regexp"
local regexp_builder = require "dromozoa.parser.regexp_builder"
local regexp_writer = require "dromozoa.parser.regexp_writer"

local function dfs_recursive(node)
  local tag = node[1]
  if tag > regexp.max_terminal_tag then
    for i = 2, #node do
      dfs_recursive(node[i])
    end
  end
  io.write(regexp.tag_names[tag], ": ", tostring(node), "\n")
  -- ???
end

--[[

u1 @1
    u2 @2
        u3 @3 %3
        u4 @4 %4
    %2
    u5 @5
        u6 @6 %6
    %5
    u7 @7 %7
%1

stack(u1)
stack([u1],{u7},u5,u2)              -- u1
stack([u1],{u7},u5,[u2],{u4},{u3})  -- u1,u2
stack([u1],{u7},u5,[u2],{u4}
stack([u1],{u7},u5,[u2])
stack([u1],{u7},u5)                 -- u1
stack([u1],{u7},[u5],{u6})          -- u1,u5
stack([u1],{u7},[u5])
stack([u1],{u7})                    -- u1
stack([u1]

{u1} / {}
{u1,u7,u5,u2} / {u1}
{u1,u7,u5,u2,u4,u3} / {u1,u2}
{u1,u7,u5,u2,u4,u3} / {u1,u2,u3}
{u1,u7,u5,u2,u4} / {u1,u2} -> u3
{u1,u7,u5,u2,u4} / {u1,u2,u4}
{u1,u7,u5,u2} / {u1,u2} -> u4
{u1,u7,u5} / {u1} -> u2
{u1,u7,u5,u6} / {u1,u5}
{u1,u7,u5,u6} / {u1,u5,u6}
{u1,u7,u5} / {u1,u5} -> u6
{u1,u7} / {u1} -> u5
{u1,u7} / {u1,u7}
{u1} / {u1} -> u7
{} / {} -> u1



]]

local function dfs_stack(node)
  local stack = { node }
  while true do
    local n = #stack
    if n == 0 then
      break
    end
    local u = stack[n]
    stack[n] = nil
    io.write(regexp.tag_names[u[1]], ": ", tostring(u), "\n")
    local tag = u[1]
    if tag > regexp.max_terminal_tag then
      for i = #u, 2, -1 do
        local v = u[i]
        stack[#stack + 1] = v
      end
    end
  end
end

local function dfs_stack(u)
  local stack1 = { u }
  local stack2 = {}

  while true do
    local m = #stack1
    local n = #stack2
    local u = stack1[m]
    if u == nil then
      break
    end
    local tag = u[1]
    if u == stack2[n] then
      stack1[m] = nil
      stack2[n] = nil
      io.write(regexp.tag_names[tag], ": ", tostring(u), "\n")
    else
      if tag > regexp.max_terminal_tag then
        for i = #u, 2, -1 do
          stack1[m + 4 - i] = u[i]
        end
      end
      stack2[n + 1] = u
    end
  end
end

local P = regexp_builder.P
local R = regexp_builder.R
local S = regexp_builder.S

-- local p = P"a"^"*"
-- local p = (P"X" ^{2,4}) ^"*"
-- local p = P"abcdef"
-- local p = (S"ab"^"*" * P"c"^"?")^"*"
-- local p = (P"a"^"*")^"*"
-- local p = P"abcd" + P"aacd"
local p = P"if" + "elseif" + "then" + "end" + "while"

print(dumper.encode(p, { pretty = true, stable = ture }))
-- print("--")
-- dfs_recursive(p)
-- print("--")
-- dfs_stack(p)

local data = regexp.tree_to_nfa(p)
local transitions = data.transitions
local epsilons = data.epsilons
local n = data.max_state
-- print(dumper.encode(transitions, { pretty = true, stable = ture }))

print(data.start_state, dumper.encode(data.accept_states))

local dfa, epsilon_closures = regexp.nfa_to_dfa(data)
local dfa_transitions = dfa.transitions
local max_dfa = dfa.max_state
local dfa_accepts = dfa.accept_states

-- local epsilon_closures, dfa_transitions, max_dfa, dfa_accepts = regexp.nfa_to_dfa(data)
-- print("--")
-- print(dumper.encode(dfa_transitions, { pretty = true, stable = true }))
-- print(dumper.encode(dfa_accepts, { pretty = true, stable = true }))

regexp_writer.write_automaton(assert(io.open("test-dfa1.dot", "w")), dfa):close()

dfa, partitions = regexp.minimize_dfa(dfa)
local dfa_transitions = dfa.transitions
local max_dfa = dfa.max_state
local dfa_accepts = dfa.accept_states

-- print("--")
print(dumper.encode(dfa, { pretty = true, stable = true }))
-- print(dumper.encode(dfa_accepts, { pretty = true, stable = true }))

regexp_writer.write_automaton(assert(io.open("test-nfa.dot", "w")), data):close()

regexp_writer.write_automaton(assert(io.open("test-dfa2.dot", "w")), dfa):close()

-- finish vertexでepsilon closure
--
local function graph_dfs_stack(data, u)
  local epsilons1 = data.epsilons1
  local epsilons2 = data.epsilons2
  local conditions = data.conditions
  local transitions = data.transitions

  local stack1 = { u }
  local stack2 = {}
  local color = { [u] = true }

  while true do
    local u = stack1[#stack1]
    if u == nil then
      break
    end

    -- stack1[#stack1] = nil

    if u == stack2[#stack2] then
      stack1[#stack1] = nil
      stack2[#stack2] = nil
      print("u", u)
    else
      local t = {}
      local v = transitions[u]
      if v then
        t[#t + 1] = v
      end
      local v = epsilons1[u]
      if v then
        t[#t + 1] = v
      end
      local v = epsilons2[u]
      if v then
        t[#t + 1] = v
      end
      for i = 1, #t do
        local v = t[i]
        if not color[v] then
          color[v] = true
          stack1[#stack1 + 1] = v
        end
      end
      stack2[#stack2 + 1] = u
    end
  end
end

-- graph_dfs_stack(data, data.start_state)
