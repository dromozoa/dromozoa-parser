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

local clone = require "dromozoa.commons.clone"
local dumper = require "dromozoa.commons.dumper"
local equal = require "dromozoa.commons.equal"
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
    :_ (P[[\]] * R"09"^{1,3}) :sub(2, -1) :int(10) :char() :push()
    :_ (P[[\x]] * R"09AFaf"^{2}) :sub(3, -1) :int(16) :char() :push()
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
  :_ (P"[" * P"="^"*" * "[\n") :sub(2, -3)  :join("]", "]") :hold() :call "long_string" :mark() :skip()
  :_ (P"[" * P"="^"*" * "[") :sub(2, -2) :join("]", "]") :hold() :call "long_string" :mark() :skip()
  :_ ((R"09"^"+" * (P"." * R"09"^"*")^"?" + P"." * R"09"^"+") * (S"eE" * S"+-"^"?" * R"09"^"+")^"?") :as "Numeral"
  :_ (P"0" * S"xX" * (R"09AFaf"^"+" * (P"." * R"09AFaf"^"*")^"?" + P"." * R"09AFaf"^"+") * (S"pP" * S"+-"^"?" * R"09"^"+")^"?") :as "Numeral"
  :_ (P"--[" * P"="^"*" * P"[") :sub(4, -2) :join("]", "]") :hold() :call "long_comment" :skip()
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
  :_ "{stat}" "stat" :list()

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
  :_ "varlist" "," "var" :list()

_"var"
  :_ "Name"
  :_ "var | ( exp )" "[" "exp" "]"
  :_ "var | ( exp )" "." "Name"
  :_ "functioncall" "[" "exp" "]"
  :_ "functioncall" "." "Name"

_"namelist"
  :_ "Name"
  :_ "namelist" "," "Name" :list()

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
  :_ "{fieldsep field}" "fieldsep" "field" :list()

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

parser:compile("test_parser.lua")

do
  local compiled_parser = assert(loadfile("test_parser.lua"))()
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
  local compiled_parser = assert(loadfile("test_parser.lua"))()
  assert(equal(parser, compiled_parser))
  parser = compiled_parser
end

grammar:write_set_of_items("test-set-of-items.txt", set_of_items)
grammar:write_graphviz("test-graph.dot", set_of_items, transitions)
grammar:write_table("test.html", parser)
grammar:write_conflicts(io.stdout, conflicts)

--[====[
do
  local max_state = parser.max_state
  local max_terminal_symbol = grammar.max_terminal_symbol
  local max_symbol = parser.max_symbol
  local parser_table = parser.table

  do
    local actions = {}
    local gotos = {}
    local map = {}

    for state = 1, max_state do
      for symbol = 1, max_symbol do
        local i = state * max_symbol + symbol
        local v = parser_table[i]
        if v then
          if symbol <= max_terminal_symbol then
            local t = actions[state]
            if not t then
              t = {}
              actions[state] = t
            end
            t[symbol] = v
          else
            local k = symbol - max_terminal_symbol
            local t = gotos[state]
            if not t then
              t = {}
              gotos[state] = t
            end
            t[k] = v
          end
          -- T[i] = v
          -- local x = symbol
          -- local y = state
          -- local t = T[y]
          -- if not t then
          --   t = {}
          --   T[y] = t
          -- end
          -- t[x] = v
        end
      end
    end

    local map = {}
    for state = 1, max_state do
      local a = actions[state]
      if a then
        local key = dumper.encode(a, {stable=true})
        local b = map[key]
        if map[key] then
          print("hit action", key)
          actions[state] = b
        else
          map[key] = a
        end
      end
      local g = gotos[state]
      if g then
        local key = dumper.encode(a, {stable=true})
        local h = map[key]
        if not map[key] then
          print("hit goto")
          gotos[state] = h
        else
          map[key] = g
        end
      end
    end

    collectgarbage()
    collectgarbage()
    local c1 = collectgarbage("count")
    actions = nil
    gotos = nil
    collectgarbage()
    collectgarbage()
    local c2 = collectgarbage("count")
    print("count", c1 - c2)
  end
end
]====]

local function dump(file, value)
  local out = assert(io.open(file, "w"))
  out:write("return ")
  out:write(dumper.encode(value, { pretty = true, stable = true }))
  out:write("\n")
  out:close()
end

dump("test_lexer_dump.lua", lexer.lexers)
lexer:compile("test_lexer.lua")

do
  local compiled_lexer = assert(loadfile("test_lexer.lua"))()
  collectgarbage()
  collectgarbage()
  local c1 = collectgarbage("count")
  compiled_lexer = nil
  collectgarbage()
  collectgarbage()
  local c2 = collectgarbage("count")
  print("lexer memory", c1 - c2)
end

local compiled_lexer = assert(loadfile("test_lexer.lua"))()
compiled_lexer:compile("test_lexer2.lua")
-- lexer = compiled_lexer

local source_lexers = clone(lexer.lexers)
for i = 1, #source_lexers do
  local lexer = source_lexers[i]
  lexer.items = nil
  lexer.name = nil
  lexer.type = nil
end
dump("test_source_lexer_dump.lua", source_lexers)
dump("test_compiled_lexer_dump.lua", compiled_lexer.lexers)
assert(equal(source_lexers, compiled_lexer.lexers))

--[====[
do
  local set_of_transitions = {}
  do
    local lexers = lexer.lexers
    local TMAP = {}
    for i = 1, #lexers do
      local lexer = lexers[i]
      local automaton = lexer.automaton
      if automaton then
        local max_state = automaton.max_state
        local transitions = {}
--[[
        for from = 1, max_state do
          local empty = true
          local copy = {}
          for char = 0, 255 do
            local to = automaton.transitions[char][from]
            if to then
              copy[char] = to
              empty = false
            end
          end
          if not empty then
            local key = dumper.encode(copy)
            if TMAP[key] then
              print("hit!")
              transitions[from] = TMAP[key]
            else
              TMAP[key] = copy
              transitions[from] = copy
            end
          end
        end
]]

        for char = 0, 255 do
          local empty = true
          local copy = {}
          for from, to in pairs(automaton.transitions[char]) do
            copy[from] = to
            empty = false
          end
          if not empty then
            local key = dumper.encode(copy)
            if TMAP[key] then
              -- print("hit!")
              transitions[char] = TMAP[key]
            else
              TMAP[key] = copy
              transitions[char] = copy
            end
          end
        end

--[[
        for char = 0, 255 do
          local empty = true
          for from, to in pairs(automaton.transitions[char]) do
            local x = from
            local y = char
            -- local x = char
            -- local y = from

            local t = transitions[x]
            if not t then
              t = {}
              transitions[x] = t
            end
            t[y] = to
            empty = false
          end
        end
]]
        set_of_transitions[#set_of_transitions + 1] = transitions
      end
    end
  end
  collectgarbage()
  collectgarbage()
  local c1 = collectgarbage("count")

  set_of_transitions = nil

  collectgarbage()
  collectgarbage()
  local c2 = collectgarbage("count")
  print("count", c1 - c2)
end
]====]

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
}
]====]

local position = 1
local root
local node = {}
repeat
  local symbol, p, i, j, rs, ri, rj = assert(lexer(source, position))
  root = assert(parser(symbol, rs:sub(ri, rj), nil, source, p, i, j - 1, rs, ri, rj))
  node.p = p
  node.i = i
  node.j = j
  position = j
until symbol == 1

parser:write_graphviz("test.dot", root)

print(root[0], root.p)

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
    if node.s then
      local s = node.s
      local p = node.p
      local i = node.i
      local j = node.j
      result[#result + 1] = s:sub(p, j)
    end
  else
    for i = node.n, 1, -1 do
      stack1[#stack1 + 1] = node[i]
    end
    stack2[n2 + 1] = node
  end
end
result[#result + 1] = source:sub(node.p, node.i - 1)

io.write(table.concat(result))
assert(table.concat(result) == source)

