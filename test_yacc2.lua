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

local regexp = require "dromozoa.regexp"
local scan = require "dromozoa.regexp.scan"
local scanner = require "dromozoa.regexp.scanner"
local identity_generator = require "dromozoa.parser.identity_generator"

local tk = identity_generator()

local re = regexp("/\\*"):concat(regexp(".*"):difference(".*\\*/.*")):concat("\\*/"):set_token(tk.COMMENT)
  :branch("[[:space:]]+", tk.WHITESPACE)
  :branch("[[:alpha:]._][[:alnum:]._]*", tk.IDENTIFIER)
  :branch(":", tk.COLON)
  :branch(";", tk.SEMICOLON)
  :branch("\\|", tk.VERTICAL_LINE)

re:write_graphviz(assert(io.open("test-re.dot", "w"))):close()

local actions = {}
for i = 1, #tk do
  actions[i] = scanner.PUSH
end
actions[tk.COMMENT] = scanner.SKIP
actions[tk.WHITESPACE] = scanner.SKIP

local text = io.read("*a")
local tokens, begins, ends = scan({ re:compile() }, actions, text)

for i = 1, #tokens do
  print(tokens[i], text:sub(begins[i], ends[i]))
end

local function parser()
  local _i = 1
  local _stack = {}

  local self = {}

  function self:parse()
    if self:rules() then
      if _i == #tokens + 1 and #_stack == 1 then
        return self:pop()
      end
    end
    error("parse error at position " .. _i)
  end

  function self:pop()
    local n = #_stack
    local v = _stack[n]
    _stack[n] = nil
    return v
  end

  function self:push(v)
    local n = #_stack
    _stack[n + 1] = v
    return true
  end

  function self:match(token, push)
    local i = _i
    if tokens[i] == token then
      if push then
        self:push(text:sub(begins[i], ends[i]))
      end
      _i = i + 1
      return true
    end
  end

  function self:rules()
    if self:rule() then
      local a = { "rules", self:pop() }
      while self:rule() do
        a[#a + 1] = self:pop()
      end
      return self:push(a)
    end
  end

  function self:rule()
    if self:match(tk.IDENTIFIER, true) then
      local a = { "rule", self:pop() }
      if self:match(tk.COLON) then
        self:rbody()
        a[#a + 1] = self:pop()
        while self:match(tk.VERTICAL_LINE) do
          self:rbody()
          a[#a + 1] = self:pop()
        end
        if self:match(tk.SEMICOLON) then
          return self:push(a)
        end
      end
    end
  end

  function self:rbody()
    local a = { "rbody" }
    while self:match(tk.IDENTIFIER, true) do
      a[#a + 1] = self:pop()
    end
    return self:push(a)
  end

  return self
end

local p = parser()
print(json.encode(p:parse()))
