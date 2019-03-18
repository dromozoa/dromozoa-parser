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

local function build(source, result)
  local handle = assert(io.open(source))
  local lines = {}

  local state = 1
  for line in io.lines(source) do
    if state == 1 then
      if not line:find "^%-%-" then
        state = 2
      end
    elseif state == 2 then
      if line ~= "" then
        state = 3
      end
    end
    if state == 3 then
      lines[#lines + 1] = line
    end
  end

  local content = table.concat(lines, "\n")
  local s = ""
  while true do
    if not content:find("]" .. s .. "]", 1, true) then
      break
    end
    s = s .. "="
  end

  local out = assert(io.open(result, "w"))
  out:write("return [", s, "[\n")
  for i = 1, #lines do
    out:write(lines[i], "\n")
  end
  out:write("]", s, "]\n")
  out:close()
end

build("dromozoa/parser/lexer/execute.lua", "dromozoa/parser/lexer/runtime.lua")
build("dromozoa/parser/parser/execute.lua", "dromozoa/parser/parser/runtime.lua")
