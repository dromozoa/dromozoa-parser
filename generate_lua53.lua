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

local builder = require "dromozoa.parser.builder"

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
  :_ (RE[["[^\\"]*"]]) :as "LiteralString" :sub(2, -2) :attr("type", "string")
  :_ (RE[['[^\\']*']]) :as "LiteralString" :sub(2, -2) :attr("type", "string")
  :_ ("[[\n" * (RE[[.*]] - RE[[.*\]\].*]]) * "]]") :as "LiteralString" :sub(4, -3) :attr("type", "string")
  :_ ("[[" * (RE[[.*]] - RE[[.*\]\].*]]) * "]]") :as "LiteralString" :sub(3, -3) :attr("type", "string")
  :_ [["]] :skip() :call "dq_string" :mark()
  :_ [[']] :skip() :call "sq_string" :mark()
  :_ (RE[[\[=*\[\n]]) :sub(2, -3) :join("]", "]") :hold() :skip() :call "long_string" :mark()
  :_ (RE[[\[=*\[]]) :sub(2, -2) :join("]", "]") :hold() :skip() :call "long_string" :mark()
  :_ (RE[[\d+]]) :as "IntegerConstant" :attr("type", "integer")
  :_ (RE[[0[xX][0-9A-Fa-f]+]]) :as "IntegerConstant" :attr("type", "integer")
  :_ (RE[[(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?]]) :as "FloatConstant" :attr("type", "float")
  :_ (RE[[0[xX]([0-9A-Fa-f]+(\.[0-9A-Fa-f]*)?|\.[0-9A-Fa-f]+)([pP][+-]?\d+)?]]) :as "FloatConstant" :attr("type", "float")
  :_ ("--[[" * (RE[[.*]] - RE[[.*\]\].*]]) * "]]") :skip()
  :_ (RE[[--\[=+\[]]) :sub(4, -2) :join("]", "]") :hold() :skip() :call "long_comment"
  :_ ("--" * (RE[[[^\n]*]] - RE[[\[=*\[.*]]) * "\n") : skip()

string_lexer(_:lexer "dq_string")
  :_ [["]] :as "LiteralString" :concat() :ret() :attr("type", "string")

string_lexer(_:lexer "sq_string")
  :_ [[']] :as "LiteralString" :concat() :ret() :attr("type", "string")

_:search_lexer "long_string"
  :when() :as "LiteralString" :concat() :ret() :attr("type", "string")
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
  :_ "block" :attr "state" :attr "scope"

_"block"
  :_ ()
  :_ "retstat"
  :_ "stats"
  :_ "stats" "retstat"

_"stats"
  :_ "stat"
  :_ "stats" "stat" {[1]={2}}

_"stat"
  :_ ";"
  :_ "varlist" "=" "explist" :attr("order", {3,2,1})
  :_ "functioncall"
  :_ "label"
  :_ "break"
  :_ "goto" "Name"
  :_ "do" "block" "end" :attr "scope"
  :_ "while" "exp" "do" "block" "end" :attr "scope" :attr "loop"
  :_ "repeat" "block" "until" "exp" :attr "scope" :attr "loop"
  :_ "if_clauses" "end"
  :_ "for" "local_name" "=" "exp" "," "exp" "do" "block" "end" :attr("order", {1,4,5,6,3,2,7,8,9}) :attr "scope" :attr "loop"
  :_ "for" "local_name" "=" "exp" "," "exp" "," "exp" "do" "block" "end" :attr("order", {1,4,5,6,7,8,3,2,9,10,11}) :attr "scope" :attr "loop"
  :_ "for" "namelist" "in" "explist" "do" "block" "end" :attr("order", {1,4,3,2,5,6,7}) :attr "scope" :attr "loop"
  :_ "function" "funcname" "funcbody"
  :_ "local" "function" "local_name" "funcbody"
  :_ "local" "namelist"
  :_ "local" "namelist" "=" "explist" :attr("order", {1,4,3,2})

_"if_clauses"
  :_"if_clause"
  :_"if_clause" "else_clause"
  :_"if_clause" "elseif_clauses"

_"elseif_clauses"
  :_ "elseif_clause"
  :_ "elseif_clause" "else_clause"
  :_ "elseif_clause" "elseif_clauses"

_"if_clause"
  :_ "if" "exp" "then" "block" :attr "scope"

_"elseif_clause"
  :_ "elseif" "exp" "then" "block" :attr "scope"

_"else_clause"
  :_ "else" "block" :attr "scope"

_"retstat"
  :_ "return"
  :_ "return" ";"
  :_ "return" "explist"
  :_ "return" "explist" ";"

_"label"
  :_ "::" "Name" "::"

_"funcname"
  :_ "funcnames"
  :_ "funcnames" ":" "Name"

_"funcnames"
  :_ "Name"
  :_ "funcnames" "." "Name" {[1]={2,3}}

_"varlist"
  :_ "var" :attr(1, "def")
  :_ "varlist" "," "var" :attr(3, "def") {[1]={2,3}}

_"var"
  :_ "Name"
  :_ "prefixexp" "[" "exp" "]"
  :_ "prefixexp" "." "Name"
  :_ "functioncall" "[" "exp" "]"
  :_ "functioncall" "." "Name"

_"namelist"
  :_ "Name"
  :_ "namelist" "," "Name" {[1]={2,3}}

_"explist"
  :_ "exp"
  :_ "explist" "," "exp" {[1]={2,3}}

_"exp"
  :_ "nil"
  :_ "false"
  :_ "true"
  :_ "IntegerConstant" :attr "loadk"
  :_ "FloatConstant" :attr "loadk"
  :_ "LiteralString" :attr "loadk"
  :_ "..."
  :_ "functiondef"
  :_ "prefixexp"
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
  :_ "-" "exp" :prec "UNM" :attr "unop"
  :_ "not" "exp" :attr "unop"
  :_ "#" "exp" :attr "unop"
  :_ "~" "exp" :prec "BNOT" :attr "unop"

-- prefixexp without functioncall
_"prefixexp"
  :_ "var"
  :_ "(" "exp" ")"

_"functioncall"
  :_ "prefixexp" "args"
  :_ "prefixexp" ":" "Name" "args"
  :_ "functioncall" "args"
  :_ "functioncall" ":" "Name" "args"

_"args"
  :_ "(" ")"
  :_ "(" "explist" ")"
  :_ "tableconstructor"
  :_ "LiteralString"

_"functiondef"
  :_ "function" "funcbody"

_"funcbody"
  :_ "(" ")" "block" "end" :attr "state" :attr "scope"
  :_ "(" "parlist" ")" "block" "end" :attr "state" :attr "scope"

_"parlist"
  :_ "namelist"
  :_ "namelist" "," "..."
  :_ "..."

_"tableconstructor"
  :_ "{" "}"
  :_ "{" "fieldlist" "}"
  :_ "{" "fieldlist" "fieldsep" "}"

_"fieldlist"
  :_ "field"
  :_ "fieldlist" "fieldsep" "field" {[1]={2,3}}

_"field"
  :_ "[" "exp" "]" "=" "exp"
  :_ "Name" "=" "exp"
  :_ "exp"

_"fieldsep"
  :_ ","
  :_ ";"

_"local_name"
  :_ "Name"

local lexer, grammar = _:build()
local parser, conflicts = grammar:lr1_construct_table(grammar:lalr1_items())
grammar:write_conflicts(io.stderr, conflicts)
lexer:compile("dromozoa/parser/lexers/lua53_lexer.lua")
parser:compile("dromozoa/parser/parsers/lua53_parser.lua")
