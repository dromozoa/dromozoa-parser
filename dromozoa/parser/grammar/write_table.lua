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

local _ = element

local style = _"style" { [[
@import url('https://fonts.googleapis.com/css?family=Roboto+Mono');

td {
  font-family: 'Roboto Mono', monospace;
  text-align: center;
}
]]}

local head = _"head" {
  _"meta" {
    charset = "UTF-8";
  };
  _"title" {
    "table";
  };
  _"link" {
    rel = "stylesheet";
    href = "https://cdnjs.cloudflare.com/ajax/libs/github-markdown-css/2.10.0/github-markdown.min.css";
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

  local table = _"table" {
    _"tr" {
      _"td" { rowspan = 2, "STATE" };
      _"td" { colspan = max_terminal_symbol, "ACTION" };
      _"td" { colspan = max_nonterminal_symbol - min_nonterminal_symbol, "GOTO" };
    }
  }

  local tr = _"tr" {}
  for i = 2, min_nonterminal_symbol - 1 do
    tr[#tr + 1] = _"td" { symbol_names[i] }
  end
  tr[#tr + 1] = _"td" { symbol_names[1] }
  for i = min_nonterminal_symbol + 1, max_nonterminal_symbol do
    tr[#tr + 1] = _"td" { symbol_names[i] }
  end
  table[#table + 1] = tr

  for i = 1, max_state do
    local tr = _"tr" {
      _"td" { i };
    }

    local t = actions[i]
    for j = 2, min_nonterminal_symbol do
      local data
      local action = j == min_nonterminal_symbol and t[1] or t[j]
      if action then
        if action <= max_state then
          data = "s" .. action
        else
          local reduce = action - max_state - 1
          if reduce == 0 then
            data = "acc"
          else
            data = "r" .. reduce
          end
        end
      end
      tr[#tr + 1] = _"td" { data }
    end

    local t = gotos[i]
    for j = min_nonterminal_symbol + 1, max_nonterminal_symbol do
      tr[#tr + 1] = _"td" { t[j - max_terminal_symbol] }
    end

    table[#table + 1] = tr
  end

  local doc = html5_document(_"html" {
    head;
    _"body" {
      _"div" {
        class = "markdown-body";
        table;
      };
    };
  })

  doc:serialize(out)
  out:write "\n"
  return out
end
