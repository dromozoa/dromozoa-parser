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

local encode_string = require "dromozoa.parser.dumper.encode_string"
local reference = require "dromozoa.parser.dumper.reference"

local reserved_words = {
  ["and"] = true;
  ["break"] = true;
  ["do"] = true;
  ["else"] = true;
  ["elseif"] = true;
  ["end"] = true;
  ["false"] = true;
  ["for"] = true;
  ["function"] = true;
  ["goto"] = true;
  ["if"] = true;
  ["in"] = true;
  ["local"] = true;
  ["nil"] = true;
  ["not"] = true;
  ["or"] = true;
  ["repeat"] = true;
  ["return"] = true;
  ["then"] = true;
  ["true"] = true;
  ["until"] = true;
  ["while"] = true;
}

local function keys(value)
  local number_keys = {}
  local string_keys = {}
  local positive_count = 0
  for k in pairs(value) do
    local t = type(k)
    if t == "number" then
      number_keys[#number_keys + 1] = k
      if k > 0 then
        positive_count = positive_count + 1
      end
    elseif t == "string" then
      string_keys[#string_keys + 1] = k
    end
  end
  table.sort(number_keys)
  table.sort(string_keys)
  return number_keys, string_keys, positive_count
end

local function encode(value)
  local t = type(value)
  if t == "number" then
    return ("%.17g"):format(value)
  elseif t == "string" then
    return encode_string(value)
  elseif t == "boolean" then
    if value then
      return "true"
    else
      return "false"
    end
  elseif t == "table" then
    if getmetatable(value) == reference.metatable then
      return value.name
    else
      local number_keys, string_keys, positive_count = keys(value)
      local n = #number_keys
      local data = {}
      if n > 0 then
        local max = number_keys[#number_keys]
        if positive_count * 1.8 < max then
          for i = 1, #number_keys do
            local k = number_keys[i]
            data[#data + 1] = "[" .. k .. "]=" .. encode(value[k])
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
          for i = 1, #number_keys do
            local k = number_keys[i]
            if k > 0 then
              break
            end
            data[#data + 1] = "[" .. k .. "]=" .. encode(value[k])
          end
        end
      end
      for i = 1, #string_keys do
        local k = string_keys[i]
        if k:match("^[%a_][%w_]*$") and not reserved_words[k] then
          data[#data + 1] = k .. "=" .. encode(value[k])
        else
          -- data[#data + 1] = "[" .. encode_string(k) .. "]=" .. encode(value[k])
          data[#data + 1] = "[" .. encode_string(k) .. "]=" .. encode(value[k])
        end
      end
      return "{" .. table.concat(data, ",") .. "}"
    end
  end
end

local function compact(self, out, value)
  if type(value) == "table" then
    local that = {}
    local number_keys, string_keys = keys(value)
    for i = 1, #number_keys do
      local k = number_keys[i]
      local v = value[k]
      if type(v) == "table" then
        that[k] = compact(self, out, v)
      else
        that[k] = v
      end
    end
    for i = 1, #string_keys do
      local k = string_keys[i]
      local v = value[k]
      if type(v) == "table" then
        that[k] = compact(self, out, v)
      else
        that[k] = v
      end
    end
    local map = self.map
    local code = encode(that)
    local name = map[code]
    if name then
      return reference(name)
    else
      local n = self.n + 1
      self.n = n
      name = "_[" .. n .. "]"
      map[code] = name
      out:write(name, " = ", code, "\n")
      return reference(name)
    end
  else
    return value
  end
end

local class = {
  keys = keys;
}
local metatable = {
  __index = class;
}
class.metatable = metatable

function class:dump(out, value)
  out:write("local _ = {}\n")
  return compact(self, out, value).name
end

return setmetatable(class, {
  __call = function ()
    return setmetatable({ map = {}, n = 0 }, metatable)
  end;
})
