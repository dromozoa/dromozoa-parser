# iteration

走査の対象を削除しても動かしたいのであればリンクリストにする。

## for

```
local t = {...}
for i = 1, #t do
	-- ???
end
```

## ipairs

### Lua 5.3

> will iterate over the key–value pairs `(1,t[1])`, `(2,t[2])`, ..., up to the first nil value.

### Lua 5.2 (ja)

> そのテーブルの整数キーが存在しない最初のところまで、 ペア`(1,t[1])`、`(2,t[2])`、...を巡回します。

## next

### Lua 5.3

> The behavior of next is undefined if, during the traversal, you assign any value to a non-existent field in the table. You may however modify existing fields. In particular, you may clear existing fields.

### Lua 5.2 (ja)

> 巡回中にテーブル内の存在しないフィールドに値を代入すると、nextの動作は未定義になります。ただし既存のフィールドを変更することはできます。例えば、既存のフィールドを消去してもかまいません。


## handle

```
local function create_handle(this)
  return handle
end
local function remove_handle(this, handle)
end
```

## allocator(n)

```
local function new()
end
local function delete(handle)
end
local function get(handle)
end
local function put(handle, ...)
end
```
