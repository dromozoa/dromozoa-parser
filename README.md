# dromozoa-parser

Parser generator toolkit.

## DSL

Operator | Type | Example | Regexp | Description
----|----|----|----|----
`P(1)` | atom | `P(1)` | `.` | any
`P(char)` | atom | `P"x"` | `x` | one character
`S(set)` | atom | `S"abc"` | `[abc]` | set
`R(range)` | atom | `R"a-z"` | `[a-z]` | range
`-atom` | atom | `-P"x"` | `[^x]` | negative
`atom + atom` | atom | `P"0" + P"9"` | `[09]` | union




