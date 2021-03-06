# dromozoa-parser

Parser generator toolkit.

## Lexer

### Regular Expression DSL

| Operator            | Example                                              | Regular Expression        | Description              |
|---------------------|------------------------------------------------------|---------------------------|--------------------------|
| `P(n)`              | `P(1)`                                               | `.`                       | any                      |
| `P(string)`         | `P"abc"`                                             | `abc`                     | literal                  |
| `S(set)`            | `S"02468"`                                           | `[02468]`                 | set                      |
| `R(range)`          | `R"09af"`                                            | `[0-9a-f]`                | range                    |
| `-pattern`          | `-R"09af"`                                           | `[^0-9a-f]`               | character level negation |
| `pattern * pattern` | `S"abc" * P"def"`                                    | `[abc]def`                | concatenation            |
| `pattern + pattern` | `P"abc" + P"def"`                                    | <code>abc&#124;def</code> | union                    |
| `pattern^"*"`       | `P"abc"^"*"`                                         | `(abc)*`                  | `0` or more repetition   |
| `pattern^"+"`       | `P"abc"^"+"`                                         | `(abc)+`                  | `1` or more repetition   |
| `pattern^"?"`       | `P"abc"^"?"`                                         | `(abc)?`                  | optional                 |
| `pattern^n`         | `P"abc"^3`                                           | `(abc){3,}`               | `n` or more repetition   |
| `pattern^-n`        | `P"abc"^-3`                                          | `(abc){0,3}`              | `0` to `n` repetition    |
| `pattern^{n}`       | `P"abc"^{3}`                                         | `(abc){3}`                | `n` repetition           |
| `pattern^{m,n}`     | `P"abc"^{3,5}`                                       | `(abc){3,5}`              | `m` to `n` repetition    |
| `pattern - pattern` | `(P(1)^"*" - P(1)^"*" * P"abc" * P(1)^"*") * P"abc"` | `.*?abc`                  | difference               |

### Regular Expression AST

| Code | Operator            | #Operands | Description            |
|-----:|---------------------|----------:|------------------------|
|    1 | `[`                 |         1 | character class        |
|    2 | `.`                 |         2 | concatenation          |
|    3 | <code>&#124;</code> |         2 | union                  |
|    4 | `*`                 |         1 | `0` or more repetition |
|    5 | `?`                 |         1 | optional               |
|    6 | `-`                 |         2 | difference             |

### Actions

| Code | Operator                  | #Operands | Skip | Description                  |
|-----:|---------------------------|----------:|:----:|------------------------------|
|    1 | `:skip()`                 |         0 | yes  | skip                         |
|    2 | `:push()`                 |         0 | yes  | push                         |
|    3 | `:concat()`               |         0 |      | concat                       |
|    4 | `:call "label"`           |         1 |      | call                         |
|    5 | `:ret()`                  |         0 |      | return                       |
|    6 | `"string"`                |         1 |      | substitute                   |
|    7 | `:hold()`                 |         0 |      | hold                         |
|    8 | `:mark()`                 |         0 |      | mark                         |
|    9 | `:sub(i, j=-1)`           |         2 |      | substring                    |
|   10 | `:int(base=10)`           |         1 |      | convert to integer           |
|   11 | `:char()`                 |         0 |      | convert to char              |
|   12 | `:join(head, tail)`       |         2 |      | join                         |
|   13 | `:utf8(i, j=-1)`          |         2 |      | encode utf8                  |
|   14 | `:utf8(i, j=-1, k, l=-1)` |         4 |      | encode utf8 (surrogate pair) |
|   15 | `:add(value)`             |         1 |      | add integer                  |
|   16 | `:normalize_eol()`        |         0 |      | normalize end-of-line        |

## Parser

### Precedence Associativities

| Code | Associativity |
|-----:|---------------|
|    1 | left          |
|    2 | right         |
|    3 | nonassoc      |

### Special Symbols

| Code | Name               | Symbol |
|-----:|--------------------|--------|
|    0 | `epsilon`          | ϵ      |
|    1 | `marker_end`       | $      |
|   -1 | `marker_lookahead` | #      |

### Conflict Resolutions

| Code | Action |
|-----:|--------|
|    1 | shift  |
|    2 | reduce |
|    3 | error  |

### Semantic Actions

| Code | Operator               | #Operands | Description   |
|-----:|------------------------|----------:|---------------|
|    1 | `{[1]={2,3,"symbol"}}` |         2 | collapse node |
|    2 | `{1,2,3,"symbol"}`     |         1 | create node   |

```
_"X" :_ "A" "GT" "B"
_"X" :_ "A" "GT" "B" {1,2,3}
<node symbol="X">
  <node symbol="A"/>
  <node symbol="GT"/>
  <node symbol="B"/>
</node>

_"X" :_ "A" "GT" "B" {3,"LT",1}
<node symbol="X">
  <node symbol="B"/>
  <node symbol="LT"/>
  <node symbol="A"/>
</node>

_"X" :_ "A" "GT" "B" {[2]={1,3}}
<node symbol="GT">
  <node symbol="A"/>
  <node symbol="B"/>
</node>

_"X" :_ "A" "GT" "B" {["LT"]={3,1}}
<node symbol="LT">
  <node symbol="B"/>
  <node symbol="A"/>
</node>
```

### Attribute Actions

| Code | Operator                    | #Operands | Description         |
|-----:|-----------------------------|----------:|---------------------|
|    1 | `:attr(key, value=true)`    |         2 | set attribute       |
|    2 | `:attr(i, key, value=true)` |         3 | set child attribute |

### Node

| Name  | Type      | Terminal Only | Description              |
|-------|-----------|:-------------:|--------------------------|
| `[0]` | `integer` |               | head symbol              |
| `[i]` | `integer` |               | body symbols             |
| `.p`  | `integer` |      yes      | skipped position         |
| `.i`  | `integer` |      yes      | start position           |
| `.j`  | `integer` |      yes      | end position             |
| `.rs` | `string`  |      yes      | resulting string         |
| `.ri` | `integer` |      yes      | resulting start position |
| `.rj` | `integer` |      yes      | resulting end position   |
| `.n`  | `integer` |      yes      | line number              |
| `.c`  | `integer` |      yes      | column number            |
