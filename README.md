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

| Code | Operator            | #Operands | Description            |
|-----:|---------------------|----------:|------------------------|
|    1 | `[`                 |         1 | character class        |
|    2 | `concat`            |         2 | concatenation          |
|    3 | <code>&#124;</code> |         2 | union                  |
|    4 | `*`                 |         1 | `0` or more repetition |
|    5 | `?`                 |         1 | optional               |
|    6 | `-`                 |         2 | difference             |

## Lexer Action

| Code | Operator   | #Operands | Example            |
|-----:|------------|----------:|--------------------|
|    1 | `default`  |         0 |                    |
|    2 | `skip`     |         0 | `{}`               |
|    3 | `goto`     |         1 | `{"goto","label"}` |
|    4 | `call`     |         1 | `{"call","label"}` |
|    5 | `return`   |         0 | `{"return"}`       |
|    6 | `function` |         1 | `{function()end}`  |

