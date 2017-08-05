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

local placeholder_metatable = {}

local function placeholder(name)
  return setmetatable({ name = name }, placeholder_metatable)
end

local function is_placeholder(value)
  return type(value) == "table" and getmetatable(value) == placeholder_metatable
end

local function encode(value)
  local t = type(value)
  if t == "number" then
    return ("%.17g"):format(value)
  elseif t == "string" then
    return ("%q"):format(value)
  elseif t == "table" then
    if getmetatable(value) == placeholder_metatable then
      return value.name
    else
      local min
      local max
      local n = 0
      for k in pairs(value) do
        assert(type(k) == "number" and k % 1 == 0)
        if not min or min > k then
          min = k
        end
        if not max or max < k then
          max = k
        end
        n = n + 1
      end
      if not min then
        return "{}"
      end
      local data = {}
      if min < 1 or n * 1.8 < max then
        for i = min, max do
          local v = value[i]
          if v then
            data[#data + 1] = "[" .. i .. "]=" .. encode(v)
          end
        end
      else
        for i = 1, max do
          local v = value[i]
          if v then
            data[#data + 1] = encode(v)
          else
            data[#data + 1] = "nil"
          end
        end
      end
      return "{" .. table.concat(data, ",") .. "}"
    end
  end
end

local function compact(out, root)
  local nodes = {}
  local stack1 = { root }
  local stack2 = {}
  while true do
    local n1 = #stack1
    local n2 = #stack2
    local node = stack1[n1]
    if not node then
      break
    end
    if node == stack2[n2] then
      stack1[n1] = nil
      stack2[n2] = nil
      local v = {}
      for i = 1, #node do
        v[i] = node[i]
      end
      -- out:write(encode(node), "\n")
    else
      if type(node) == "table" then
        for k, v in pairs(node) do
          if type(v) == "table" then
            stack1[#stack1 + 1] = v
          end
        end
      end
      stack2[n2 + 1] = node
    end
  end
end

local function compact(out, key, value, map)
  if type(value) == "table" then
    local that = {}
    for k, v in pairs(value) do
      if type(v) == "table" then
        that[k] = compact(out, k, v, map)
      else
        that[k] = v
      end
    end
    local code = encode(that)
    local name = map[code]
    if name then
      return placeholder(name)
    else
      local n = map.n + 1
      map.n = n
      name = "_" .. n
      map[code] = name
      out:write("local ", name, " = ", code, "\n")
      return placeholder(name)
    end
  else
    return value
  end
end

return function (out, value)
  local map = { n = 0 }
  local that = compact(out, "(root)", value, map)
  out:write(encode(value), "\n")
  out:write(encode(that), "\n")
  -- compact(out, value)
  return out
end
