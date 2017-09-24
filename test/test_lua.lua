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

local equal = require "dromozoa.commons.equal"
local unix = require "dromozoa.unix"
local builder = require "dromozoa.parser.builder"

local timer = unix.timer()

local RE = builder.regexp
local _ = builder()

local function string_lexer(lexer)
  return lexer
    :_ [[\a]] "\a" :push()
    :_ [[\b]] "\b" :push()
    :_ [[\f]] "\f" :push()
    :_ [[\n]] "\n" :push()
    :_ [[\r]] "\r" :push()
    :_ [[\t]] "\t" :push()
    :_ [[\v]] "\v" :push()
    :_ [[\\]] "\\" :push()
    :_ [[\"]] "\"" :push()
    :_ [[\']] "\'" :push()
    :_ (RE[[\\z\s*]]) :skip()
    :_ (RE[[\\\d{1,3}]]) :sub(2) :int(10) :char() :push()
    :_ (RE[[\\u\{[0-9A-Fa-f]+\}]]) :utf8(4, -2) :push()
    :_ (RE[[[^\\"]+]]) :push()
end

timer:start()

_:lexer()
  :_ (RE[[\s+]]) :skip()
  :_ "and"
  :_ "break"
  :_ "do"
  :_ "else"
  :_ "elseif"
  :_ "end"
  :_ "false"
  :_ "for"
  :_ "function"
  :_ "goto"
  :_ "if"
  :_ "in"
  :_ "local"
  :_ "nil"
  :_ "not"
  :_ "or"
  :_ "repeat"
  :_ "return"
  :_ "then"
  :_ "true"
  :_ "until"
  :_ "while"
  :_ "+"
  :_ "-"
  :_ "*"
  :_ "/"
  :_ "%"
  :_ "^"
  :_ "#"
  :_ "&"
  :_ "~"
  :_ "|"
  :_ "<<"
  :_ ">>"
  :_ "//"
  :_ "=="
  :_ "~="
  :_ "<="
  :_ ">="
  :_ "<"
  :_ ">"
  :_ "="
  :_ "("
  :_ ")"
  :_ "{"
  :_ "}"
  :_ "["
  :_ "]"
  :_ "::"
  :_ ";"
  :_ ":"
  :_ ","
  :_ "."
  :_ ".."
  :_ "..."
  :_ (RE[[[A-Za-z_]\w*]]) :as "Name"
  :_ (RE[["[^\\"]*"]]) :as "LiteralString" :sub(2, -2)
  :_ (RE[['[^\\']*']]) :as "LiteralString" :sub(2, -2)
  :_ [["]] :skip() :call "dq_string" :mark()
  :_ [[']] :skip() :call "sq_string" :mark()
  :_ (RE[[\[=*\[\n]]) :sub(2, -3) :join("]", "]") :hold() :skip() :call "long_string" :mark()
  :_ (RE[[\[=*\[]]) :sub(2, -2) :join("]", "]") :hold() :skip() :call "long_string" :mark()
  :_ (RE[[(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?]]) :as "Numeral"
  :_ (RE[[0[xX]([0-9A-Fa-f]+(\.[0-9A-Fa-f]*)?|\.[0-9A-Fa-f]+)([pP][+-]?\d+)?]]) :as "Numeral"
  :_ (RE[[--\[=*\[]]) :sub(4, -2) :join("]", "]") :hold() :skip() :call "long_comment"
  :_ (RE[[--[^\n]*\n]]) :skip()

string_lexer(_:lexer "dq_string")
  :_ [["]] :as "LiteralString" :concat() :ret()

string_lexer(_:lexer "sq_string")
  :_ [[']] :as "LiteralString" :concat() :ret()

_:search_lexer "long_string"
  :when() :as "LiteralString" :concat() :ret()
  :otherwise() :push()

_:search_lexer "long_comment"
  :when() :skip() :ret()
  :otherwise() :skip()

_ :left "or"
  :left "and"
  :left "<" ">" "<=" ">=" "~=" "=="
  :left "|"
  :left "~"
  :left "&"
  :left "<<" ">>"
  :right ".."
  :left "+" "-"
  :left "*" "/" "//" "%"
  :right "not" "#" "UNM" "BNOT"
  :right "^"

_"chunk"
  :_ "block"

_"block"
  :_ "{stat}" "[retstat]"

_"{stat}"
  :_ ()
  :_ "{stat}" "stat" :collapse()

_"[retstat]"
  :_ ()
  :_ "retstat"

_"stat"
  :_ ";"
  :_ "varlist" "=" "explist"
  :_ "functioncall"
  :_ "label"
  :_ "break"
  :_ "goto" "Name"
  :_ "do" "block" "end"
  :_ "while" "exp" "do" "block" "end"
  :_ "repeat" "block" "until" "exp"
  :_ "if" "exp" "then" "block" "{elseif exp then block}" "[else block]" "end"
  :_ "for" "Name" "=" "exp" "," "exp" "[, exp]" "do" "block" "end"
  :_ "for" "namelist" "in" "explist" "do" "block" "end"
  :_ "function" "funcname" "funcbody"
  :_ "local" "function" "Name" "funcbody"
  :_ "local" "namelist" "[= explist]"

_"{elseif exp then block}"
  :_ ()
  :_ "{elseif exp then block}" "elseif" "exp" "then" "block"

_"[else block]"
  :_ ()
  :_ "else" "block"

_"[, exp]"
  :_ ()
  :_ "," "exp"

_"[= explist]"
  :_ ()
  :_ "=" "explist"

_"retstat"
  :_ "return" "[explist]" "[;]"

_"[explist]"
  :_ ()
  :_ "explist"

_"[;]"
  :_ ()
  :_ ";"

_"label"
  :_ "::" "Name" "::"

_"funcname"
  :_ "Name" "{. Name}" "[: Name]"

_"{. Name}"
  :_ ()
  :_ "{. Name}" "." "Name"

_"[: Name]"
  :_ ()
  :_ ":" "Name"

_"varlist"
  :_ "var"
  :_ "varlist" "," "var" :collapse()

_"var"
  :_ "Name"
  :_ "var | ( exp )" "[" "exp" "]"
  :_ "var | ( exp )" "." "Name"
  :_ "functioncall" "[" "exp" "]"
  :_ "functioncall" "." "Name"

_"namelist"
  :_ "Name"
  :_ "namelist" "," "Name" :collapse()

_"explist"
  :_ "exp"
  :_ "explist" "," "exp" :collapse()

_"exp"
  :_ "nil"
  :_ "false"
  :_ "true"
  :_ "Numeral"
  :_ "LiteralString"
  :_ "..."
  :_ "functiondef"
  :_ "var | ( exp )"
  :_ "functioncall"
  :_ "tableconstructor"
  -- binop
  :_ "exp" "+" "exp"
  :_ "exp" "-" "exp"
  :_ "exp" "*" "exp"
  :_ "exp" "/" "exp"
  :_ "exp" "//" "exp"
  :_ "exp" "^" "exp"
  :_ "exp" "%" "exp"
  :_ "exp" "&" "exp"
  :_ "exp" "~" "exp"
  :_ "exp" "|" "exp"
  :_ "exp" ">>" "exp"
  :_ "exp" "<<" "exp"
  :_ "exp" ".." "exp"
  :_ "exp" "<" "exp"
  :_ "exp" "<=" "exp"
  :_ "exp" ">" "exp"
  :_ "exp" ">=" "exp"
  :_ "exp" "==" "exp"
  :_ "exp" "~=" "exp"
  :_ "exp" "and" "exp"
  :_ "exp" "or" "exp"
  -- unop
  :_ "-" "exp" :prec "UNM"
  :_ "not" "exp"
  :_ "#" "exp"
  :_ "~" "exp" :prec "BNOT"

-- prefixexp without functioncall
_"var | ( exp )"
  :_ "var"
  :_ "(" "exp" ")"

_"functioncall"
  :_ "var | ( exp )" "args"
  :_ "var | ( exp )" ":" "Name" "args"
  :_ "functioncall" "args"
  :_ "functioncall" ":" "Name" "args"

_"args"
  :_ "(" "[explist]" ")"
  :_ "tableconstructor"
  :_ "LiteralString"

_"functiondef"
  :_ "function" "funcbody"

_"funcbody"
  :_ "(" "[parlist]" ")" "block" "end"

_"[parlist]"
  :_ ()
  :_ "parlist"

_"parlist"
  :_ "namelist" "[, ...]"
  :_ "..."

_"[, ...]"
  :_ ()
  :_ "," "..."

_"tableconstructor"
  :_ "{" "[fieldlist]" "}"

_"[fieldlist]"
  :_ ()
  :_ "fieldlist"

_"fieldlist"
  :_ "field" "{fieldsep field}" "[fieldsep]"

_"{fieldsep field}"
  :_ ()
  :_ "{fieldsep field}" "fieldsep" "field" :collapse()

_"[fieldsep]"
  :_ ()
  :_ "fieldsep"

_"field"
  :_ "[" "exp" "]" "=" "exp"
  :_ "Name" "=" "exp"
  :_ "exp"

_"fieldsep"
  :_ ","
  :_ ";"

timer:start()
local lexer, grammar = _:build()
timer:stop()
print("build", timer:elapsed())

grammar:write_productions("test-productions.txt")

timer:start()
local set_of_items, transitions = grammar:lr0_items()
timer:stop()
print("lr0_items", timer:elapsed())

timer:start()
local set_of_items = grammar:lalr1_kernels(set_of_items, transitions)
timer:stop()
print("lalr1_kernels", timer:elapsed())

print("#set_of_items", #set_of_items)

timer:start()
for i = 1, #set_of_items do
  grammar:lr1_closure(set_of_items[i])
end
timer:stop()
print("lr1_closure", timer:elapsed())

timer:start()
local parser, conflicts = grammar:lr1_construct_table(set_of_items, transitions)
timer:stop()
print("lr1_construct_table", timer:elapsed())

lexer:compile("test_lexer.lua")
parser:compile("test_parser.lua")

do
  local compiled_lexer = assert(loadfile("test_lexer.lua"))()()
  collectgarbage()
  collectgarbage()
  local c1 = collectgarbage("count")
  compiled_lexer = nil
  collectgarbage()
  collectgarbage()
  local c2 = collectgarbage("count")
  print("lexer memory", c1 - c2)
end

-- do
--   local compiled_lexer = assert(loadfile("test_lexer.lua"))()()
--   for i = 1, #lexer.lexers do
--     lexer.lexers[i].items = nil
--     lexer.lexers[i].name = nil
--     lexer.lexers[i].type = nil
--   end
--   assert(equal(lexer, compiled_lexer))
--   lexer = compiled_lexer
-- end

do
  local compiled_parser = assert(loadfile("test_parser.lua"))()()
  collectgarbage()
  collectgarbage()
  local c1 = collectgarbage("count")
  compiled_parser = nil
  collectgarbage()
  collectgarbage()
  local c2 = collectgarbage("count")
  print("parser memory", c1 - c2)
end

do
  local compiled_parser = assert(loadfile("test_parser.lua"))()()
  assert(equal(parser, compiled_parser))
  parser = compiled_parser
end

grammar:write_set_of_items("test-set-of-items.txt", set_of_items)
grammar:write_graphviz("test-graph.dot", set_of_items, transitions)
grammar:write_table("test.html", parser)
grammar:write_conflicts(io.stdout, conflicts)

local source = [====[
f(a, b, c, d)
-- local a = b + c (f)(1, 2, 3, 4, 5)
-- local a = 1 + 2 + -3^2
-- local a = 1 + 2 * 3
-- print("\77\79\0890U\x0A\x41\x42")
local a = [==[
foo
bar
baz
]==]
function f.g.h:i(x, y, z)
--   local a = b + c (f)(42)
--   return a
end
x, y, z = ...
local t0 = {}
local t1 = {"a"}
local t2 = {"a","b"}
local t3 = {"a","b","c"}
return {
  foo = 17,
  bar = 23;
  "baz";
  qux = 42;
  utf8 = "\\u{10437}=\u{10437}";
}
]====]

local terminal_nodes = assert(lexer(source))
local root = assert(parser(terminal_nodes, source))

parser:write_graphviz("test.dot", root)

local result = {}

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
    if node[0] <= parser.max_terminal_symbol then
      local p = node.p
      local j = node.j
      result[#result + 1] = source:sub(p, j)
    end
  else
    for i = #node, 1, -1 do
      stack1[#stack1 + 1] = node[i]
    end
    stack2[n2 + 1] = node
  end
end
local node = terminal_nodes[#terminal_nodes]
result[#result + 1] = source:sub(node.p, node.i - 1)

io.write(table.concat(result))
assert(table.concat(result) == source)
