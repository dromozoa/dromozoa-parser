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
  :_ "and" :attr("color", "color-operator")
  :_ "break" :attr("color", "color-statement")
  :_ "do" :attr("color", "color-statement")
  :_ "else" :attr("color", "color-statement")
  :_ "elseif" :attr("color", "color-statement")
  :_ "end" :attr("color", "color-statement")
  :_ "false" :attr("color", "color-constant")
  :_ "for" :attr("color", "color-statement")
  :_ "function" :attr("color", "color-structure")
  :_ "goto" :attr("color", "color-statement")
  :_ "if" :attr("color", "color-statement")
  :_ "in" :attr("color", "color-statement")
  :_ "local" :attr("color", "color-statement")
  :_ "nil" :attr("color", "color-constant")
  :_ "not" :attr("color", "color-operator")
  :_ "or" :attr("color", "color-operator")
  :_ "repeat" :attr("color", "color-statement")
  :_ "return" :attr("color", "color-statement")
  :_ "then" :attr("color", "color-statement")
  :_ "true" :attr("color", "color-constant")
  :_ "until" :attr("color", "color-statement")
  :_ "while" :attr("color", "color-statement")
  :_ "+" :attr("color", "color-operator")
  :_ "-" :attr("color", "color-operator")
  :_ "*" :attr("color", "color-operator")
  :_ "/" :attr("color", "color-operator")
  :_ "%" :attr("color", "color-operator")
  :_ "^" :attr("color", "color-operator")
  :_ "#" :attr("color", "color-operator")
  :_ "&" :attr("color", "color-operator")
  :_ "~" :attr("color", "color-operator")
  :_ "|" :attr("color", "color-operator")
  :_ "<<" :attr("color", "color-operator")
  :_ ">>" :attr("color", "color-operator")
  :_ "//" :attr("color", "color-operator")
  :_ "==" :attr("color", "color-operator")
  :_ "~=" :attr("color", "color-operator")
  :_ "<=" :attr("color", "color-operator")
  :_ ">=" :attr("color", "color-operator")
  :_ "<" :attr("color", "color-operator")
  :_ ">" :attr("color", "color-operator")
  :_ "=" :attr("color", "color-operator")
  :_ "("
  :_ ")"
  :_ "{" :attr("color", "color-structure")
  :_ "}" :attr("color", "color-structure")
  :_ "["
  :_ "]"
  :_ "::"
  :_ ";"
  :_ ":"
  :_ ","
  :_ "."
  :_ ".." "operator"
  :_ "..."
  :_ (RE[[[A-Za-z_]\w*]]) :as "Name"
  :_ (RE[["[^\\"]*"]]) :as "LiteralString" :sub(2, -2) :attr("color", "color-constant")
  :_ (RE[['[^\\']*']]) :as "LiteralString" :sub(2, -2) :attr("color", "color-constant")
  :_ ("[[\n" * (RE[[.*]] - RE[[.*\]\].*]]) * "]]") :as "LiteralString" :sub(4, -3) :attr("color", "color-constant")
  :_ ("[[" * (RE[[.*]] - RE[[.*\]\].*]]) * "]]") :as "LiteralString" :sub(3, -3) :attr("color", "color-constant")
  :_ [["]] :skip() :call "dq_string" :mark()
  :_ [[']] :skip() :call "sq_string" :mark()
  :_ (RE[[\[=*\[\n]]) :sub(2, -3) :join("]", "]") :hold() :skip() :call "long_string" :mark()
  :_ (RE[[\[=*\[]]) :sub(2, -2) :join("]", "]") :hold() :skip() :call "long_string" :mark()
  :_ (RE[[(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?]]) :as "Numeral" :attr("color", "color-constant")
  :_ (RE[[0[xX]([0-9A-Fa-f]+(\.[0-9A-Fa-f]*)?|\.[0-9A-Fa-f]+)([pP][+-]?\d+)?]]) :as "Numeral" :attr("color", "color-constant")
  :_ ("--[[" * (RE[[.*]] - RE[[.*\]\].*]]) * "]]") :skip()
  :_ (RE[[--\[=+\[]]) :sub(4, -2) :join("]", "]") :hold() :skip() :call "long_comment"
  :_ ("--" * (RE[[[^\n]*]] - RE[[\[=*\[.*]]) * "\n") : skip()

string_lexer(_:lexer "dq_string")
  :_ [["]] :as "LiteralString" :concat() :ret() :attr("color", "color-constant")

string_lexer(_:lexer "sq_string")
  :_ [[']] :as "LiteralString" :concat() :ret() :attr("color", "color-constant")

_:search_lexer "long_string"
  :when() :as "LiteralString" :concat() :ret() :attr("color", "color-constant")
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
  :_ "block" :attr "scope"

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
  :_ "varlist" "=" "explist"
  :_ "functioncall"
  :_ "label"
  :_ "break"
  :_ "goto" "Name"
  :_ "do" "block" "end" :attr "scope"
  :_ "while" "exp" "do" "block" "end" :attr "scope"
  :_ "repeat" "block" "until" "exp" :attr "scope"
  :_ "if_clause" "end"
  :_ "if_clause" "else_clause" "end"
  :_ "if_clause" "elseif_clauses" "end"
  :_ "if_clause" "elseif_clauses" "else_clause" "end"
  :_ "for" "Name" "=" "exp" "," "exp" "do" "block" "end" :attr "scope"
  :_ "for" "Name" "=" "exp" "," "exp" "," "exp" "do" "block" "end" :attr "scope"
  :_ "for" "namelist" "in" "explist" "do" "block" "end" :attr "scope"
  :_ "function" "funcname" "funcbody"
  :_ "local" "function" "Name" "funcbody"
  :_ "local" "namelist"
  :_ "local" "namelist" "=" "explist"

_"if_clause"
  :_ "if" "exp" "then" "block" :attr "scope"

_"elseif_clauses"
  :_ "elseif_clause"
  :_ "elseif_clauses" "elseif_clause" {[1]={2}}

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
  :_ "var"
  :_ "varlist" "," "var" {[1]={2,3}}

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
  :_ "Numeral"
  :_ "LiteralString"
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
  :_ "-" "exp" :prec "UNM"
  :_ "not" "exp"
  :_ "#" "exp"
  :_ "~" "exp" :prec "BNOT"

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
  :_ "(" ")" "block" "end" :attr "scope"
  :_ "(" "parlist" ")" "block" "end" :attr "scope"

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

local lexer, grammar = _:build()
local parser, conflicts = grammar:lr1_construct_table(grammar:lalr1_items())
grammar:write_conflicts(io.stderr, conflicts)
lexer:compile("dromozoa/parser/lexers/lua53_lexer.lua")
parser:compile("dromozoa/parser/parsers/lua53_parser.lua")
