-- Copyright (C) 2017,2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local element = require "dromozoa.dom.element"
local html5_document = require "dromozoa.dom.html5_document"

local style = element "style" { [[
table {
  border-collapse: collapse;
}

td {
  border: 1px solid #CCC;
  text-align: center;
}
]]}

local head = element "head" {
  element "meta" {
    charset = "UTF-8";
  };
  element "title" {
    "table";
  };
  style;
}

return function (self, out, data)
  local symbol_names = self.symbol_names
  local max_terminal_symbol = self.max_terminal_symbol
  local min_nonterminal_symbol = self.min_nonterminal_symbol
  local max_nonterminal_symbol = self.max_nonterminal_symbol
  local max_state = data.max_state
  local table = data.table
  local actions = data.actions
  local gotos = data.gotos

  local table = element "table" {
    element "tr" {
      element "td" { rowspan = 2, "STATE" };
      element "td" { colspan = max_terminal_symbol, "ACTION" };
      element "td" { colspan = max_nonterminal_symbol - min_nonterminal_symbol, "GOTO" };
    }
  }

  local tr = element "tr" {}
  table[#table + 1] = tr
  for i = 2, min_nonterminal_symbol do
    if i == min_nonterminal_symbol then
      i = 1
    end
    tr[#tr + 1] = element "td" { symbol_names[i] }
  end
  for i = min_nonterminal_symbol + 1, max_nonterminal_symbol do
    tr[#tr + 1] = element "td" { symbol_names[i] }
  end

  for i = 1, max_state do
    local tr = element "tr" {
      element "td" { i - 1 };
    }
    table[#table + 1] = tr
    local t = actions[i]
    for j = 2, min_nonterminal_symbol do
      if j == min_nonterminal_symbol then
        j = 1
      end
      local td = element "td" {}
      tr[#tr + 1] = td
      if t then
        local action = t[j]
        if action then
          if action <= max_state then
            td[1] = "s" .. (action - 1)
          else
            local reduce = action - max_state
            if reduce == 1 then
              td[1] = "acc"
            else
              td[1] = "r" .. (reduce - 1)
            end
          end
        end
      end
    end
    local t = gotos[i]
    for j = min_nonterminal_symbol + 1, max_nonterminal_symbol do
      local td = element "td" {}
      tr[#tr + 1] = td
      if t then
        local action = t[j - max_terminal_symbol]
        if action then
          td[1] = action - 1
        end
      end
    end
  end

  local doc = html5_document(element "html" {
    head;
    element "body" { table };
  })

  doc:serialize(out)
  out:write "\n"
  return out
end
