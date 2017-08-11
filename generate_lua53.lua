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
  :_ (RE[["[^\\"]*"]]) :as "LiteralString" :sub(2, -2)
  :_ (RE[['[^\\']*']]) :as "LiteralString" :sub(2, -2)
  :_ ("[[\n" * (RE[[.*]] - RE[[.*\]\].*]]) * "]]") :as "LiteralString" :sub(4, -3)
  :_ ("[[" * (RE[[.*]] - RE[[.*\]\].*]]) * "]]") :as "LiteralString" :sub(3, -3)
  :_ [["]] :skip() :call "dq_string" :mark()
  :_ [[']] :skip() :call "sq_string" :mark()
  :_ (RE[[\[=*\[\n]]) :sub(2, -3) :join("]", "]") :hold() :skip() :call "long_string" :mark()
  :_ (RE[[\[=*\[]]) :sub(2, -2) :join("]", "]") :hold() :skip() :call "long_string" :mark()
  :_ (RE[[(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?]]) :as "Numeral"
  :_ (RE[[0[xX]([0-9A-Fa-f]+(\.[0-9A-Fa-f]*)?|\.[0-9A-Fa-f]+)([pP][+-]?\d+)?]]) :as "Numeral"
  :_ ("--[[" * (RE[[.*]] - RE[[.*\]\].*]]) * "]]") :skip()
  :_ (RE[[--\[=+\[]]) :sub(4, -2) :join("]", "]") :hold() :skip() :call "long_comment"
  :_ ("--" * (RE[[[^\n]*]] - RE[[\[=*\[.*]]) * "\n") : skip()

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
  :_ "{" "}" {}
  :_ "{" "fieldlist" "}" {2}

_"fieldlist"
  :_ "field {fieldsep field}" "[fieldsep]" {[1]={}}

_"field {fieldsep field}"
  :_ "field"
  :_ "field {fieldsep field}" "fieldsep" "field" {[1]={3}}

_"[fieldsep]"
  :_ ()
  :_ "fieldsep"

_"field"
  :_ "[" "exp" "]" "=" "exp" {2,5}
  :_ "Name" "=" "exp" {1,3}
  :_ "exp"

_"fieldsep"
  :_ ","
  :_ ";"

local lexer, grammar = _:build()
local parser, conflicts = grammar:lr1_construct_table(grammar:lalr1_items())
grammar:write_conflicts(io.stderr, conflicts)
lexer:compile("dromozoa/parser/lexers/lua53_lexer.lua")
parser:compile("dromozoa/parser/parsers/lua53_parser.lua")
