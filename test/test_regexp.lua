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
local unpack = require "dromozoa.commons.unpack"
local regexp = require "dromozoa.parser.regexp"
local regexp_builder = require "dromozoa.parser.regexp_builder"

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

local p = P"abc" ^ "?"
print(dumper.encode(p, { pretty = true, stable = ture }))
print("--")
dfs_recursive(p)
print("--")
dfs_stack(p)

local transitions, n = regexp.tree_to_nfa(p)
print(dumper.encode(transitions, { pretty = true, stable = ture }))

local out = assert(io.open("test.dot", "w"))
out:write([[
digraph g {
graph [rankdir=LR];
]])
for i = 1, n do
  local e1 = transitions[-1][i]
  local e2 = transitions[-2][i]
  if e1 then
    out:write(("%d->%d;\n"):format(i, e1))
  end
  if e2 then
    out:write(("%d->%d;\n"):format(i, e2))
  end
  local t = {}
  for j = 0, 255 do
    local x = transitions[j][i]
    if x then
      local y = t[x]
      if not y then
        y = {}
        t[x] = y
      end
      y[#y + 1] = j
    end
  end
  for x, y in pairs(t) do
    out:write(("%d->%d[label=<%s>];\n"):format(i, x, string.char(unpack(y))))
  end
end
out:write("}\n")
out:close()
