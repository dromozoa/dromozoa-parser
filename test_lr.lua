-- Copyright (C) 2015 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local json = require "dromozoa.json"
local clone = require "dromozoa.commons.clone"

--[[
E : E '+' T
  | T
T : T '*' F
  | F
F : '(' E ')'
  | id
]]

--[[
local map = {
  "+", "*", "(", ")", "id",
  "E", "T", "F",
}
]]
local enum = {
  "E", "B",
  "*", "+",
  "0", "1",
}
enum[0] = "."
enum[100] = "E'"

local map = clone(enum)
for k, v in pairs(enum) do
  map[v] = k
end

local function translate(this)
  if type(this) == "table" then
    local that = {}
    for k, v in pairs(this) do
      that[k] = translate(v)
    end
    return that
  else
    return assert(map[this], this)
  end
end

--[[
local G = translate {
  { "E", "E", "+", "T" };
  { "E", "T" };
  { "T", "T", "*", "F" };
  { "T", "F" };
  { "F", "(", "E", ")" };
  { "F", "id" };
}
]]
local G = translate {
  { "E", "E", "*", "B" };
  { "E", "E", "+", "B" };
  { "E", "B" };
  { "B", "0" };
  { "B", "1" };
}

print(json.encode(translate(G)))

local function equal(a, b)
  local t = type(a)
  if t == type(b) then
    if t == "table" then
      for k, v in next, a do
        if not equal(v, b[k]) then
          return false
        end
      end
      for k, v in next, b do
        if not equal(v, a[k]) then
          return false
        end
      end
      return true
    else
      return a == b
    end
  else
    return false
  end
end

local function find_marker(items)
  for i = 2, #items - 1 do
    local item = items[i]
    if item == 0 then
      return i
    end
  end
end

local function closure(G, I)
  local J = clone(I)
  print("closure arg", json.encode(translate(I)))
  local added = {}
  for i = 1, #J do
    local items = J[i]
    added[items[1]] = true
  end
  local done
  repeat
    done = true
    for i = 1, #J do
      local items = J[i]
      local marker = find_marker(items)
      if marker then
        local item = items[marker + 1]
        if not added[item] then
          local itemset = {}
          for i = 1, #G do
            local items = G[i]
            if items[1] == item then
              local items = clone(items)
              table.insert(items, 2, 0)
              J[#J + 1] = items
              done = false
            end
          end
          added[item] = true
        end
      end
    end
  until done
  return J
end

local function items(G, S, items_set, items_list)
  for i = 1, #S do
    items_set[#items_set + 1] = S[i]
  end
  local C = closure(G, S)
  local X = {}
  local X_set = {}
  for i = 1, #C do
    local item = C[i]
    local marker = find_marker(item)
    local value = item[marker + 1]
    if not X_set[value] then
      X[#X + 1] = value
      X_set[value] = true
    end
  end
  for i = 1, #X do
    local x = X[i]
    local itemset = {}
    for j = 1, #C do
      local item = clone(C[j])
      local marker = find_marker(item)
      local value = item[marker + 1]
      if value == x then
        item[marker] = value
        item[marker + 1] = 0
        itemset[#itemset + 1] = item
      end
    end
    items_list[#items_list + 1] = closure(G, itemset)
  end
  print(json.encode(translate(items_list)))
  for i = 1, #items_list do
    local itemset = items_list[i]
    for j = 1, #itemset do
      local item = itemset[j]
      if find_marker(item) then
        local found = false
        for k = 1, #items_set do
          if equal(item, items_set[k]) then
            found = true
            break
          end
        end
        if not found then
          items(G, { item }, items_set, items_list)
        end
      end
    end
  end
end

print(json.encode(translate(closure(G, translate { { "E'", ".", "E" } }))))
items(G, translate { { "E'", ".", "E" } }, {}, {})

--[==[
local G = {
  [map.E] = {
    { map.E, map["+"], map.T };
    { map.T };
  };
  [map.T] = {
    { map.T, map["*"], map.F };
    { map.F };
  };
  [map.F] = {
    { map["("], map.E, map[")"] };
    { map.ID };
  };
  [map["E'"]] = {
    { map.E };
  };
  [map["S"]] = {
    { map.E };
  };
  [map["S'"]] = {
    { map.S };
  };
}

local function equal(a, b)
  local t = type(a)
  if t == type(b) then
    if t == "table" then
      for k, v in next, a do
        if not equal(v, b[k]) then
          return false
        end
      end
      for k, v in next, b do
        if not equal(v, a[k]) then
          return false
        end
      end
      return true
    else
      return a == b
    end
  else
    return false
  end
end

local function closure(G, I)
  local J = clone(I)
  local added = {}
  for a, j in ipairs(J) do
    added[j[1]] = true
  end
  local m
  repeat
    m = 0
    for a, j in ipairs(J) do
      for b = 2, #j - 1 do
        if j[b] == 0 and G[j[b + 1]] then
          if not added[j[b + 1]] then
            for c, u in ipairs(G[j[b + 1]]) do
              local B = { j[b + 1], 0 }
              for i = 1, #u do
                B[#B + 1] = u[i]
              end
              J[#J + 1] = B
              m = m + 1
            end
            added[j[b + 1]] = true
          end
        end
      end
    end
  until m == 0
  return J
end

-- [null,null,null,[[9,4,0,7,5],[7,0,7,2,8],[7,0,8],[8,0,8,3,9],[8,0,9]],null,[[9,6,0]],[[11,7,0],[7,7,0,2,8]],[[7,8,0],[8,8,0,3,9]],[[8,9,0]],null,[[12,11,0]]]

local function items(G)
  local C = closure(G, { { map["S'"], 0, map.S } })
  local GOTO = {}
  local m = 0
  repeat
    local set = {}
    for a, c in ipairs(C) do
      for b = 2, #c - 1 do
        local B = clone(c)
        if B[b] == 0 then
          local v = B[b + 1]
          B[b], B[b + 1] = B[b + 1], B[b]
          if set[v] then
            local x = set[v]
            x[#x + 1] = B
          else
            set[v] = { B }
          end
        end
      end
    end
    for k, v in pairs(set) do
      set[k] = closure(G, v)
    end
    print(json.encode(set))
    break
  until m == 0
  return GOTO
end

print(json.encode(G))
local J = closure(G, { { map["E'"], 0, map.E } })
print(json.encode(J))
items(G)

local function is_dot(x)
  return x == map["."]
end

local function is_terminal(x)
  return map["+"] <= x and x <= map["ID"]
end

local function is_nonterminal(x)
  return map["E"] <= x and x <= map["F"]
end

local function closure(G, I)
end

local start = map.E
local grammar = {
  { map.E, map.E, map["+"], map.T };
  { map.E, map.T };
  { map.T, map.T, map["*"], map.F };
  { map.T, map.F };
  { map.F, map["("], map.E, map[")"] };
  { map.F, map.ID };
}

local item_set = {}
for i = 1, #grammar do
  local g = grammar[i]
  for j = 1, #g do
    local item = clone(g)
    table.insert(item, j + 1, map["."])
    item_set[#item_set + 1] = item
  end
end

print(json.encode(item_set))
]==]




