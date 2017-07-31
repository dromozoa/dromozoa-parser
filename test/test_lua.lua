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

local unix = require "dromozoa.unix"
local builder = require "dromozoa.parser.builder"

local timer = unix.timer()

local P = builder.pattern
local R = builder.range
local S = builder.set
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
    :_ (P[[\z]] * S" \t\n\v\f\r"^"*") :skip()
    :_ (P[[\]] * R"09"^{1,3}) (function (rs, ri, rj) return string.char(tonumber(rs:sub(ri + 1, rj))) end) :push()
    :_ (P[[\x]] * R"09AFaf"^{2}) (function (rs, ri, rj) return string.char(tonumber(rs:sub(ri + 2, rj), 16)) end) :push()
    -- \u{...}
    :_ ((-S[[\"]])^"+") :push()
end

timer:start()

_:lexer()
  :_ (S" \t\n\v\f\r"^"+") :skip()
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
  :_ ((R"AZaz" + P"_") * (R"09AZaz" + P"_")^"*") :as "Name"
  :_ [["]] :call "dq_string" :mark() :skip()
  :_ [[']] :call "sq_string" :mark() :skip()
  :_ (P"[" * P"="^"*" * "[\n") (function (rs, ri, rj) return "]" .. rs:sub(ri + 1, rj - 2) .. "]" end) :hold() :call "long_string" :mark() :skip()
  :_ (P"[" * P"="^"*" * "[") (function (rs, ri, rj) return "]" .. rs:sub(ri + 1, rj - 1) .. "]" end) :hold() :call "long_string" :mark() :skip()
  :_ ((R"09"^"+" * (P"." * R"09"^"*")^"?" + P"." * R"09"^"+") * (S"eE" * S"+-"^"?" * R"09"^"+")^"?") :as "Numeral"
  :_ (P"0" * S"xX" * (R"09AFaf"^"+" * (P"." * R"09AFaf"^"*")^"?" + P"." * R"09AFaf"^"+") * (S"pP" * S"+-"^"?" * R"09"^"+")^"?") :as "Numeral"
  :_ (P"--[" * P"="^"*" * P"[") (function (rs, ri, rj) return "]" .. rs:sub(ri + 3, rj - 1) .. "]" end) :hold() :call "long_comment" :skip()
  :_ (P"--" * ((-S"\n")^"+")) :skip()

string_lexer(_:lexer "dq_string")
  :_ [["]] :as "LiteralString" :concat() :ret()

string_lexer(_:lexer "sq_string")
  :_ [[']] :as "LiteralString" :concat() :ret()

_:search_lexer "long_string"
  :when() :as "LiteralString" :concat() :ret()
  :otherwise() :push()

_:search_lexer "long_comment"
  :when() :ret() :skip()
  :otherwise() :skip()

timer:stop()
print("define lexer", timer:elapsed())

timer:start()

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

timer:stop()
print("define percedence", timer:elapsed())

timer:start()

_"chunk"
  :_ "block"

_"block"
  :_ "{stat}" "[retstat]"

_"{stat}"
  :_ ()
  :_ "{stat}" "stat"

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
  :_ "varlist" "," "var"

_"var"
  :_ "Name"
  :_ "var | ( exp )" "[" "exp" "]"
  :_ "var | ( exp )" "." "Name"
  :_ "functioncall" "[" "exp" "]"
  :_ "functioncall" "." "Name"

_"namelist"
  :_ "Name"
  :_ "namelist" "," "Name"

_"explist"
  :_ "exp"
  :_ "explist" "," "exp" :list()

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
  :_ "{fieldsep field}" "fieldsep" "field"

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

timer:stop()
print("define grammar", timer:elapsed())

timer:start()
local lexer, grammar = _:build()
timer:stop()
print("build", timer:elapsed())

-- print("== symbols ==")
-- for i = 1, #grammar.symbol_names do
--   io.write("(", i, ") ", grammar.symbol_names[i], "\n")
-- end

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
-- local a = [==[
-- foo
-- bar
-- baz
-- ]==]
function f.g.h:i(x, y, z)
--   local a = b + c (f)(42)
--   return a
end
]====]

local position = 1
repeat
  local symbol, ps, pi, pj, rs, ri, rj = assert(lexer(source, position))
  tree = assert(parser(symbol, {
    value = rs:sub(ri, rj);
    -- value = source:sub(pi, pj - 1);
    -- value = source:sub(ps, pj - 1);
  }))
  position = pj
until symbol == 1

parser:write_graphviz("test.dot", tree)
