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

local linked_hash_table = require "dromozoa.commons.linked_hash_table"
local pairs = require "dromozoa.commons.pairs"
local sequence = require "dromozoa.commons.sequence"
local scanners = require "dromozoa.parser.scanners"
local scanner = require "dromozoa.parser.builder.scanner"
local symbol_table = require "dromozoa.parser.builder.symbol_table"

local class = {}

function class.new()
  return {
    scanners = linked_hash_table()
  }
end

function class:scanner(name)
  local that = scanner()
  self.scanners[name] = that
  return that
end

function class:build()
  local terminal_symbols = symbol_table()
  terminal_symbols.n = 1
  terminal_symbols[1] = "$"

  local env = {}
  local i = 0
  for name in pairs(self.scanners) do
    i = i + 1
    env[name] = i
  end

  local data = sequence()
  for _, scanner in pairs(self.scanners) do
    data:push(scanner:build(terminal_symbols, env))
  end

  return scanners(data), terminal_symbols
end

class.metatable = {
  __index = class;
}

function class.metatable:__call(name)
  if name then
    return self:scanner(name)
  else
    return self:build()
  end
end

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), class.metatable)
  end;
})
