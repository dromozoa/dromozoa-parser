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

local R = builder.range
local S = builder.set
local _ = builder()

local function atom_escape(lexer)
  return lexer
    -- DecimalEscape
    :_ "\\0" "\0" :as "DecimalEscape"
    -- CharacterEscape
    :_ "\\f" "\f" :as "ControlEscape"
    :_ "\\n" "\n" :as "ControlEscape"
    :_ "\\r" "\r" :as "ControlEscape"
    :_ "\\t" "\t" :as "ControlEscape"
    :_ "\\v" "\v" :as "ControlEscape"
    :_ ("\\c" * R"AZaz") :as "ControlLetter" :sub(3, -1) :int(36) :add(-9) :char()
    :_ ("\\x" * R"09AFaf"^{2}) :as "HexEscapeSequence" :sub(3, -1) :int(16) :char()
    :_ ("\\u" * S"Dd" * S"89ABab" * R"09AFaf"^{2} * "\\u" * S"Dd" * R"CFcf" * R"09AFaf"^{2}) :as "RegExpUnicodeEscapeSequence" :utf8_surrogate_pair(3, 6, 9, 12)
    :_ ("\\u" * R"09AFaf"^{4}) :as "RegExpUnicodeEscapeSequence" :utf8(3, -1)
    :_ ("\\u{" * R"09AFaf"^"+" * "}") :as "RegExpUnicodeEscapeSequence" :utf8(4, -2)
    :_ ("\\" * (-(R"09AZaz" + "_"))) :as "IdentityEscape" :sub(2, -1)
    -- CharacterClassEscape
    :_ "\\d"
    :_ "\\D"
    :_ "\\s"
    :_ "\\S"
    :_ "\\w"
    :_ "\\W"
end

atom_escape(_:lexer())
  :_ "|"
  :_ "*"
  :_ "+"
  :_ "?"
  :_ "{" :call "repetition"
  :_ (-S"^$\\.*+?()[]{}|") :as "PatternCharacter"
  :_ "."
  :_ "("
  :_ "(?:"
  :_ ")"
  :_ "[" :call "character_class"
  :_ "[^" :call "character_class"

_:lexer "repetition"
  :_ (R"09"^"+") :as "DecimalDigits"
  :_ ","
  :_ "}" :ret()

atom_escape(_:lexer "character_class")
  :_ (-S"\\]-") :as "ClassCharacter"
  :_ "\\b" "\b"
  :_ "\\-" "-"
  :_ "-"
  :_ "]" :ret()

_"Pattern"
  :_ "Disjunction"

_"Disjunction"
  :_ "Alternative"
  :_ "Alternative" "|" "Disjunction"

_"Alternative"
  :_ "Term"
  :_ "Term" "Alternative"

_"Term"
  :_ "Atom"
  :_ "Atom" "Quantifier"

_"Quantifier"
  :_ "*"
  :_ "+"
  :_ "?"
  :_ "{" "DecimalDigits" "}"
  :_ "{" "DecimalDigits" "," "}"
  :_ "{" "DecimalDigits" "," "DecimalDigits" "}"

_"Atom"
  :_ "PatternCharacter"
  :_ "."
  :_ "AtomEscape"
  :_ "CharacterClass"
  :_ "(" "Disjunction" ")"
  :_ "(?:" "Disjunction" ")"

_"AtomEscape"
  :_ "DecimalEscape" :collapse()
  :_ "CharacterEscape" :collapse()
  :_ "CharacterClassEscape" :collapse()

_"CharacterEscape"
  :_ "ControlEscape" :collapse()
  :_ "ControlLetter" :collapse()
  :_ "HexEscapeSequence" :collapse()
  :_ "RegExpUnicodeEscapeSequence" :collapse()
  :_ "IdentityEscape" :collapse()

_"CharacterClassEscape"
  :_ "\\d"
  :_ "\\D"
  :_ "\\s"
  :_ "\\S"
  :_ "\\w"
  :_ "\\W"

_"CharacterClass"
  :_ "[" "NonemptyClassRanges" "]"
  :_ "[^" "NonemptyClassRanges" "]"

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
  :_ "-" :collapse()
  :_ "ClassAtomNoDash" :collapse()

_"ClassAtomNoDash"
  :_ "ClassCharacter" :collapse()
  :_ "ClassEscape" :collapse()

_"ClassEscape"
  :_ "DecimalEscape" :collapse()
  :_ "\\b" :collapse()
  :_ "\\-" :collapse()
  :_ "CharacterEscape" :collapse()
  :_ "CharacterClassEscape" :collapse()

local lexer, grammar = _:build()
local set_of_items, transitions = grammar:lalr1_items()
local parser, conflicts = grammar:lr1_construct_table(set_of_items, transitions)

grammar:write_conflicts(io.stderr, conflicts, true)

lexer:compile("dromozoa/parser/lexers/regexp_lexer.lua")
parser:compile("dromozoa/parser/parsers/regexp_parser.lua")
