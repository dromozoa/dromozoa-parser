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
    :_ ((-S[[\"]])^"+") :push()
    -- [TODO] more escape sequence
end

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
  :_ (R"AZaz__" * R"09AZaz__"^"*") :as "Name"
  :_ [["]] :call "string_dq" :skip()
  :_ [[']] :call "string_sq" :skip()
  -- [TODO] more strings
  :_ (R"09"^"+" * (P"." * R"09"^"*")^"?" * (S"eE" * R"09"^"+")^"?") : as "Numeral"
  -- [TODO] more numbers
  :_ (P"--" * ((-S"\n")^"+")) :skip()
  -- [TODO] more comments

string_lexer(_:lexer "string_dq")
  :_ [["]] :as "LiteralString" :concat() :ret()

string_lexer(_:lexer "string_sq")
  :_ [[']] :as "LiteralString" :concat() :ret()

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
  :_ "stats"
  :_ "stats" "retstat"

_"stats"
  :_ ()
  :_ "stats" "stat"

_"stat"
  :_ "varlist" "=" "explist"
  :_ "functioncall"
  :_ "label"
  :_ "break"
  :_ "goto" "Name"
  :_ "do" "block" "end"
  :_ "while" "exp" "do" "block" "end"
  :_ "repeat" "block" "until" "exp"
  :_ "if" "exp" "then" "block" "elseif_clauses" "else_clause" "end"
  :_ "for" "Name" "=" "exp" "," "exp" "do" "block" "end"
  :_ "for" "Name" "=" "exp" "," "exp" "," "exp" "do" "block" "end"
  :_ "for" "namelist" "in" "explist" "do" "block" "end"
  :_ "function" "funcname" "funcbody"
  :_ "local" "function" "Name" "funcbody"
  :_ "local" "namelist"
  :_ "local" "namelist" "=" "explist"

_"elseif_clauses"
  :_ ()
  :_ "elseif_clauses" "elseif" "block"

_"else_clause"
  :_ ()
  :_ "else" "block"

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
  :_ "funcnames" "." "Name"

_"varlist"
  :_ "var"
  :_ "varlist" "," "var"

_"var"
  :_ "Name"
  :_ "prefixexp" "[" "exp" "]"
  :_ "prefixexp" "." "Name"

_"namelist"
  :_ "Name"
  :_ "namelist" "," "Name"

_"explist"
  :_ "exp"
  :_ "explist" "," "exp"

_"exp"
  :_ "nil"
  :_ "false"
  :_ "true"
  :_ "Numeral"
  :_ "LiteralString"
  :_ "..."
  :_ "functiondef"
  :_ "prefixexp"
  :_ "tableconstructor"
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
  :_ "-" "exp" :prec "UNM"
  :_ "not" "exp"
  :_ "#" "exp"
  :_ "~" "exp" :prec "BNOT"

_"prefixexp"
  :_ "var"
  :_ "functioncall"
  :_ "(" "exp" ")"

_"functioncall"
  :_ "prefixexp" "args"
  :_ "prefixexp" ":" "Name" "args"

_"args"
  :_ "(" ")"
  :_ "(" "explist" ")"
  :_ "tableconstructor"
  :_ "LiteralString"

_"functiondef"
  :_ "function" "funcbody"

_"funcbody"
  :_ "(" ")" "block" "end"
  :_ "(" "parlist" ")" "block" "end"

_"parlist"
  :_ "namelist"
  :_ "namelist" "," "..."
  :_ "..."

_"tableconstructor"
  :_ "{" "}"
  :_ "{" "fieldlist" "}"

_"fieldlist"
  :_ "fieldlist_impl"
  :_ "fieldlist_impl" "fieldsep"

_"fieldlist_impl"
  :_ "field"
  :_ "fieldlist_impl" "fieldsep" "field"

_"field"
  :_ "[" "exp" "]" "=" "exp"
  :_ "Name" "=" "exp"
  :_ "exp"

_"fieldsep"
  :_ ","
  :_ ";"

local lexer, grammar = _:build()
local set_of_items, transitions = grammar:lalr1_items()
local parser, conflicts = grammar:lr1_construct_table(set_of_items, transitions)
grammar:write_set_of_items("test.dat", set_of_items)
grammar:write_table("test.html", parser)
grammar:write_conflicts(io.stdout, conflicts)
