# dromozoa-parser

Parser generator toolkit.

## Regular Expression DSL

| Operator          | Example                                        | Regular Expression        | Description              |
|-------------------|------------------------------------------------|---------------------------|--------------------------|
| `P(n)`            | `P(1)`                                         | `.`                       | any                      |
| `P(string)`       | `P"abc"`                                       | `abc`                     | literal                  |
| `S(set)`          | `S"02468"`                                     | `[02468]`                 | set                      |
| `R(range)`        | `R"09af"`                                      | `[0-9a-f]`                | range                    |
| `-atom`           | `-R"09af"`                                     | `[^0-9a-f]`               | character level negation |
| `pattern*pattern` | `S"abc"*P"def"`                                | `[abc]def`                | concatenation            |
| `pattern+pattern` | `P"abc"+P"def"`                                | <code>abc&#124;def</code> | union                    |
| `pattern^"*"`     | `P"abc"^"*"`                                   | `(abc)*`                  | `0` or more repetition   |
| `pattern^"+"`     | `P"abc"^"+"`                                   | `(abc)+`                  | `1` or more repetition   |
| `pattern^"?"`     | `P"abc"^"?"`                                   | `(abc)?`                  | optional                 |
| `pattern^n`       | `P"abc"^3`                                     | `(abc){3,}`               | `n` or more repetition   |
| `pattern^-n`      | `P"abc"^-3`                                    | `(abc){0,3}`              | `0` to `n` repetition    |
| `pattern^{n}`     | `P"abc"^{3}`                                   | `(abc){3}`                | `n` repetition           |
| `pattern^{m,n}`   | `P"abc"^{3,5}`                                 | `(abc){3,5}`              | `m` to `n` repetition    |
| `pattern-pattern` | `(P(1)^"*"-P(1)^"*"*P"abc"*P(1)^"*") * P"abc"` | `.*?abc`                  | difference               |

## Regular Expression AST

| Code | Operator            | Operand |
|-----:|---------------------|---------|
|    1 | `[`                 | `c`     |
|    2 | `concat`            | `ab`    |
|    3 | <code>&#124;</code> | `ab`    |
|    4 | `*`                 | `a`     |
|    5 | `?`                 | `a`     |
|    6 | `-`                 | `ab`    |
