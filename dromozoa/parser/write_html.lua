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

local dumper = require "dromozoa.parser.dumper"
local escape_html = require "dromozoa.parser.escape_html"

local void_elements = {
  area = true;
  base = true;
  br = true;
  col = true;
  embed = true;
  hr = true;
  img = true;
  input = true;
  keygen = true;
  link = true;
  meta = true;
  param = true;
  source = true;
  track = true;
  wbr = true;
}

local function write_html(out, node)
  local number_keys, string_keys = dumper.keys(node)
  local name = node[1]
  out:write("<", name)
  for i = 1, #string_keys do
    local key = string_keys[i]
    local value = node[key]
    local t = type(value)
    if t == "number" then
      value = ("%.17g"):format(value)
    elseif t == "boolean" then
      value = tostring(value)
    elseif t == "table" then
      if value[1] then
        value = table.concat(value, " ")
      else
        value = nil
      end
    end
    if value then
      out:write(" ", escape_html(key), "=\"", escape_html(value), "\"")
    end
  end
  out:write(">")
  if not void_elements[name] then
    if name == "script" or name == "style" then
      local value = table.concat(node, "", 2, number_keys[#number_keys])
      if value:find("[<&]") then
        assert(not value:find("%]%]>"))
        if name == "script" then
          out:write("//<![CDATA[\n", value, "//]]>")
        else
          out:write("/*<![CDATA[*/\n", value, "/*]]>*/")
        end
      else
        out:write(value)
      end
    else
      for i = 2, number_keys[#number_keys]  do
        local value = node[i]
        if type(value) == "table" then
          write_html(out, value)
        else
          out:write(escape_html(tostring(value)))
        end
      end
    end
    out:write("</", name, ">")
  end
end

return write_html
