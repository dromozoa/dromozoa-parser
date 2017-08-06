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

_:lexer()
  :_ "|"
  :_ "?"
  :_ "*"
  :_ "+"
  :_ "+"
  :_ "{"
  :_ "}"
  :_ ","
  :_ "."
  :_ "("
  :_ "(?:"
  :_ ")"
  :_ (R"09"^"+") :as "DecimalDigits"
  :_ (-S[[^$\.*+?()[]{}|]]) :as "PatternCharacter"
  :_ (P[[\]] * (R"09" + R"19" * R"09"^"*")) :as "DecimalEscape"
  :_ [[\f]] :as "ControlEscape"
  :_ [[\n]] :as "ControlEscape"
  :_ [[\r]] :as "ControlEscape"
  :_ [[\t]] :as "ControlEscape"
  :_ [[\v]] :as "ControlEscape"
  :_ (P[[\c]] * R"azAZ") :as "ControlEscape"
  :_ (P[[\x]] * R"09afAF"^{2}) :as "HexEscapeSequence"
  :_ (P[[\]] * S[[^$\.*+?()[]{}|/]]) :as "IdentityEscape"
  :_ [[\d]] :as "CharacterClassEscape"
  :_ [[\D]] :as "CharacterClassEscape"
  :_ [[\s]] :as "CharacterClassEscape"
  :_ [[\S]] :as "CharacterClassEscape"
  :_ [[\w]] :as "CharacterClassEscape"
  :_ [[\W]] :as "CharacterClassEscape"
  :_ "[" :call "character_class"
  :_ "[^" :call "character_class"
  :_ "]"

_:lexer "character_class"
  :_ (-S[[\]-]]) :as [[SourceCharacter but not one of \ or ] or -]]
  :_ (P[[\]] * (R"09" + R"19" * R"09"^"*")) :as "DecimalEscape"
  :_ [[\b]]
  :_ "-"
  :_ "]" :ret()

_"Pattern"
  :_ "Disjunction"

_"Disjunction"
  :_ "Alternative"
  :_ "Alternative" "|" "Disjunction"

_"Alternative"
  :_ ()
  :_ "Alternative" "Term"

_"Term"
  :_ "Atom"
  :_ "Atom" "Quantifier"

_"Quantifier"
  :_ "QuantifierPrefix"
  :_ "QuantifierPrefix" "?"

_"QuantifierPrefix"
  :_ "*"
  :_ "+"
  :_ "?"
  :_ "{" "DecimalDigits" "}"
  :_ "{" "DecimalDigits" "," "}"
  :_ "{" "DecimalDigits" "," "DecimalDigits" "}"

_"Atom"
  :_ "PatternCharacter"
  :_ "DecimalEscape"
  :_ "CharacterEscape"
  :_ "CharacterClassEscape"
  :_ "."
  :_ "(" "Disjunction" ")"
  :_ "(?:" "Disjunction" ")"

_"CharacterEscape"
  :_ "ControlEscape"
  :_ "HexEscapeSequence"
  :_ "IdentityEscape"

_"CharacterClass"
  :_ "[" "ClassRanges" "]"
  :_ "[^" "ClassRanges" "]"

_"ClassRanges"
  :_ ()
  :_ "NonemptyClassRanges"

_"NonemptyClassRanges"
  :_ "ClassAtom"
  :_ "ClassAtom" "NonemptyClassRangesNoDash"
  :_ "ClassAtom" "-" "ClassAtom" "ClassRanges"

_"NonemptyClassRangesNoDash"
  :_ "ClassAtom"
  :_ "ClassAtomNoDash" "NonemptyClassRangesNoDash"
  :_ "ClassAtomNoDash" "-" "ClassAtom" "ClassRanges"

_"ClassAtom"
  :_ "-"
  :_ "ClassAtomNoDash"

_"ClassAtomNoDash"
  :_ "???"
  :_ 


local lexer, grammar = _:build()
local set_of_items, transitions = grammar:lalr1_items()
local parser, conflicts = grammar:lr1_construct_table(set_of_items, transitions)

grammar:write_set_of_items("test-set-of-items.txt", set_of_items)
grammar:write_graphviz("test-graph.dot", set_of_items, transitions)
grammar:write_table("test.html", parser)
grammar:write_conflicts(io.stdout, conflicts)
