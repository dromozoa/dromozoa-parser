# container

操作 | 対応関係
----|----
`container:empty()` | C++ `empty`

```
to_array(list) / to_sequence(list)
to_table(map)
adapt_list(that)
adapt_map(that)
```

## test

```
local a = 42
test
```

## map

基本操作。

操作 | 対応関係
----|----
`list:get(key)` | `__index(key)`
`list:put(key, value)` | `__newindex(key, value)`
`list:insert(key, value)` | C++ `insert`
`list:remove(key)` | `__newindex(key, nil)` or C++ `erase`
`for key, value in list:each() do end` | `__pairs`

集合操作。

```
set_union(a, b)
set_intersection(a, b)
set_difference(a, b)
set_symmetric_difference(a, b)
```

## list (c++ sequence)

基本操作。

操作 | 対応関係
----|----
`list:get(handle)` | `__index`
`list:set(handle, value)` | `__newindex`
`list:insert([handle], value)` | `table.insert`
`list:remove([handle])` | `table.remove`
`for handle, value in list:each() do end` | `__pairs`

先頭と末尾に関する操作。

操作 | 対応関係
----|----
`list:front()` | C++ `front`
`list:back()` | C++ `back`
`list:push_front(value)` | C++ `push_front` or Perl `unshift`
`list:push_back(value)` | C++ `push_back` or Perl `push`
`list:pop_front()` | C++ `pop_front` or Perl `shift`
`list:pop_back()` | C++ `pop_back` or Perl `pop`

リストに関する操作。

操作 | 対応関係
----|----
`concat(a, b)` | JavaScript `Array.prototype.concat`
`find(list, value)` | C++ `find` or JavaScript `Array.prototype.indexOf`


List_Util.concat(a, b, c)
List(x)

## adapt

```
adapt_map(adapted)
{
	adapted = adapted;
}
```
