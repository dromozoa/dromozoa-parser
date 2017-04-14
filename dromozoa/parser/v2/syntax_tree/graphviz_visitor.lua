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

local ipairs = require "dromozoa.commons.ipairs"
local sequence_writer = require "dromozoa.commons.sequence_writer"
local json = require "dromozoa.commons.json"
local xml = require "dromozoa.commons.xml"
local graphviz = require "dromozoa.regexp.graphviz"

local class = {}

function class.new()
  return {}
end

function class:node_attributes(u)
  local out = sequence_writer():write("<<table border=\"0\" cellborder=\"1\" cellspacing=\"0\">")
  out:write("<tr><td>id</td><td>", u.id, "</td></tr>")
  for i, v in ipairs(u) do
    out:write("<tr><td>", i, "</td><td>", xml.escape(v, "%W"), "</td></tr>")
  end
  out:write("<tr><td>bodies</td><td>", xml.escape(json.encode(u.bodies), "%W"), "</td></tr>")
  return {
    shape = "plaintext";
    label = out:write("</table>>"):concat();
  }
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), metatable)
  end;
})
