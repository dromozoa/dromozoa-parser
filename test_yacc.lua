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

local regexp = require "dromozoa.regexp"
local scan = require "dromozoa.regexp.scan"
local scanner = require "dromozoa.regexp.scanner"
local dump = require "dromozoa.regexp.dump"
local identity_generator = require "dromozoa.parser.identity_generator"

local tokens = identity_generator()

local re = regexp([[/\*]])
  :concat(regexp([[.*]]):difference([[.*\*/.*]]))
  :concat([[\*/]])
  :set_token(tokens.TK_COMMENT)
  :branch("[[:space:]]+", tokens.TK_WHITESPACE)
  :branch([[[[:alpha:]._][[:alnum:]._]*]], tokens.TK_NAME)
  :branch([['\\'']], tokens["TK_ESCAPE_SEQUENCE(')"])
  :branch([['\\"']], tokens["TK_ESCAPE_SEQUENCE(\")"])
  :branch([['\\\?']], tokens["TK_ESCAPE_SEQUENCE(?)"])
  :branch([['\\\\']], tokens["TK_ESCAPE_SEQUENCE(\\)"])
  :branch([['\\a']], tokens["TK_ESCAPE_SEQUENCE(a)"])
  :branch([['\\b']], tokens["TK_ESCAPE_SEQUENCE(b)"])
  :branch([['\\f']], tokens["TK_ESCAPE_SEQUENCE(f)"])
  :branch([['\\n']], tokens["TK_ESCAPE_SEQUENCE(n)"])
  :branch([['\\r']], tokens["TK_ESCAPE_SEQUENCE(r)"])
  :branch([['\\t']], tokens["TK_ESCAPE_SEQUENCE(t)"])
  :branch([['\\v']], tokens["TK_ESCAPE_SEQUENCE(v)"])
  :branch([['\\[0-7]{1,3}']], tokens.TK_ESCAPE_OCT)
  :branch([=['\\x[[:xdigit:]]+']=], tokens.TK_ESCAPE_OCT)
  :branch("'[^'\\\n]'", tokens.TK_LITERAL)
  :branch("[[:digit:]]+", tokens.TK_NUMBER)
  :branch("%token", tokens.TK_TOKEN)
  :branch("%left", tokens.TK_LEFT)
  :branch("%right", tokens.TK_RIGHT)
  :branch("%nonassoc", tokens.TK_NONASSOC)
  :branch("%type", tokens.TK_TYPE)
  :branch("%start", tokens.TK_START)
  :branch("%%", tokens.TK_MARK)
  :branch(regexp("%\\{"):concat(regexp(".*"):difference(".*%}.*")):concat("%}"):set_token(tokens.TK_CODE))
  :branch("\\{", tokens.TK_ACTION_BEGIN)
  :branch(":", tokens["TK(:)"])
  :branch(";", tokens["TK(;)"])
  :branch("\\|", tokens["TK(|)"])

local re_action = regexp("}", tokens.TK_ACTION_END)
  :branch([[\$\$]], tokens["TK_ACTION($)"])
  :branch("\\{", tokens.TK_ACTION_BEGIN)
  :branch("[^{}$]+", tokens.TK_ACTION_TEXT)

-- re:write_graphviz(assert(io.open("test-re.dot", "w"))):close()
-- re_action:write_graphviz(assert(io.open("test-re_action.dot", "w"))):close()

-- dump(re:compile(), io.stdout)
-- dump(re_action:compile(), io.stderr)

-- os.exit()

local actions = {}
for i = 1, #tokens do
  actions[i] = scanner.PUSH
end
actions[tokens.TK_COMMENT] = scanner.SKIP
actions[tokens.TK_WHITESPACE] = scanner.SKIP
actions[tokens.TK_ACTION_BEGIN] = scanner.CALL(2)
actions[tokens.TK_ACTION_END] = scanner.RETURN


local s = io.read("*a")
local stack, begins, ends = scan({ re:compile(), re_action:compile() }, actions, s)
for i = 1, #stack do
  print(string.format("%d\t%q", stack[i], s:sub(begins[i], ends[i])))
end





-- local re = regexp(
-- 
-- local re_name = regexp("[[:alpha:]._][[:alnum:]._]*")
-- local re_literal = regexp([=['([^'\]|\\(['"?\abfnrtv]|[0-7]{1,3}|x[[:xdigit:]]+))']=])
-- local re_number = regexp("[[:digit:]]+")
-- 
-- re_comment:write_graphviz(assert(io.open("test-re_comment.dot", "w"))):close()
-- re_name:write_graphviz(assert(io.open("test-re_name.dot", "w"))):close()
-- re_literal:write_graphviz(assert(io.open("test-re_literal.dot", "w"))):close()
-- re_number:write_graphviz(assert(io.open("test-re_number.dot", "w"))):close()
-- 
-- print(arg[1])
-- print(match(re_literal:compile(), arg[1]))

