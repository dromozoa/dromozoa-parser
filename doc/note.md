# Compilers - Principles, Techniques and Tools

## Elimination of Left Recursions

任意の数の`A`-生成規則から直接左再帰を取り除く方法は、次の通りである。まず、生成規則を次のようにグループ化する。

```
A → A α_1 | A α_2 | ... | A α_m | β_1 | β_2 | ... | β_n
```

ここで、`β_i`は、`A`以外の記号で始まる文法文字列である。この`A`-生成規則を、次の生成規則によって置き換える。

```
A → β_1 A' | β_2 A' | ... | β_n A'
A' → α_1 A' | α_2 A' | ... | α_m A' | ε
```

```
非終端記号を順に並べ、A_1, A_2, ..., A_nとする。
for (i = 1, 2, ..., n) {
	for (j = 1, 2, ..., i-1) {
		現時点でのA_j-生成規則をA_j → δ_1 | δ_2 | ... | δ_kとすると、
			A_i → A_j γという形の各生成規則をA_i → δ_1 γ | δ_2 γ | ... | δ_k γで置き換える。
	}
	A_i生成規則中の直接左再帰を除去。
}
```

### メモ

```
for i = 1, n do
	for j = 1, i - 1 do
		local source_rules = A[i]生成規則
		local target_rules = {}
		for source_rule in source_rules:each() do
			if source_rule.body[1] == A[j] then
				for rule in A[j]生成規則 do
					target_rules:add()
				end
			else
				target_rules:add(source_rule)
			end
		end
	end
	A[i]生成規則中の直接左再帰を除去。
end
```

## FIRST

1. `X`が終端記号ならば、`FIRST(X) = {X}`である。
2. `X`が非終端記号ならば、生成規則`X → Y_1 Y_2 ... Y_k, k ≧ 1`について、次の条件を満たす終端記号`a`を`FIRST(X)`に加える。
	* すなわち、ある`i`について、`FIRST(Y_1), ... FIRST(Y_{i-1})`のすべてに`ε`が含まれ、つまり`Y_1 ... Y_{i-1} ⇒* ε`であり、`a`が`FIRST(Y_i)`に含まれるとき、`a`を`FIRST(X)`に加える。
	* もし、すべての`FIRST(Y_j), j = 1, 2, ..., k`に`ε`が含まれていれば、`ε`を`FIRST(X)`に加える。
3. `X → ε`という生成規則があれば、`ε`を`FIRST(X)`に加える。

任意の記号列`X_1 X_2 ... X_n`に対する`FIRST`の計算は、次のとおりである。

1. まず、`ε`を除く`FIRST(X_1)`中のすべての記号を`FIRST(X_1 X_2 ... X_n)`に入れる。
2. `FIRST(X_1)`に`ε`が含まれていれば、`ε`を除く`FIRST(X_2)`中のすべての記号をさらに加える。
3. `ε`が`FIRST(X_1)`と`FIRST(X_2)`の両方に含まれていれば、`FIRST(X_3)`について、同様の操作を行う。
4. 以下、同様である。
5. 最後に、`ε`が`FIRST(X_i), i = 1, 2, ..., n`に含まれていれば、`FIRST(X_1 X_2 ... X_n)`に`ε`を加える。

### メモ

```
local function FIRST_SYMBOL(X)
	if is_term(X) then
		return { X }
	else
		local result = {}
		for rule in X do
			if not is_epsilon(X.body) then
				result = merge(result, FIRST_SYMBOLS(X.body))
			else
				result = merge(result, { epsilon })
			end
		end
		return result
	end
end
```

```
local function FIRST_SYMBOLS(X)
	local result = {}
	for i = 1, #X do
		local removed, non_epsilon = remove_epsilon(FIRST_SYMBOL(X[i]))
		add(result, non_epsilon)
		if not removed then
			return result
		end
	end
	add(result, epsilon)
	return result
end
```

無限再帰を防ぐ必要がある。

## FOLLOW

1. Place `$` in `FOLLOW(S)`, where `S` is the start symbol, and `$` is the input right endmarker.
2. If there is a production `A → α B β`, then everything in `FIRST(β)` except `ε` is in `FOLLOW(B)`.
3. If there is a production `A → α B`, or a production `A → α B β`, where `FIRST(β)` contains `ε`, then everything in `FOLLOW(A)` is in `FOLLOW(B)`.

すべての非終端記号`A`について、`FOLLOW(A)`を計算するには、どの`FOLLOW`集合にも記号を追加できなくなるまで、次の規則を適用する。

1. `FOLLOW(S)`に`$`を入れる。ここで`S`は開始記号、`$`は入力の右端の終了マーカである。
2. `A → α B β`という形の生成規則に対しては、`ε`を除く`FIRST(β)`中のすべての記号を`FOLLOW(B)`に入れる。
3. `A → α B`または`A → α B β`で、`FIRST(β)`が`ε`を含むときは、`FOLLOW(A)`に含まれるすべての記号を`FOLLOW(B)`に入れる。

### メモ

翻訳がおかしい。

```
FOLLOW[S] += $
for head, body in pairs(rules) do
	for i = 1, #body do
		local sym = body[i]
		if is_nonterm(sym) then
			local a = view(body, 1, i - 1)
			local b = view(body, i + 1)
			local first_b = FIRST_SYMBOLS(b)
			FOLLOW[B] += first_b:remove_epsilon()
			if first_b:contains_epsilon() then
				FOLLOW[B] += FOLLOW[A]
			end
		end
	end
end
```

## 正準LR(1)構文解析表の作成

```
入力 拡大文法G'
出力 G'に対する正準LR(1)構文解析表関数ACTIONとGOTO
```

1. `G'`に対するLR(1)項集合の集まり`C' = { I_0, I_1, ..., I_n }`を作成する。
2. `I_i`から構文解析器の状態`i`を作る。状態`i`での構文解析動作は、次のようにして決定する。
	* `I_i`に`[A → α・aβ, b]`が含まれていて、`GOTO(I_i, a) = I_j`ならば、`ACTION[i,a]`に“シフト`j`”を入れる。ここで`a`は終端記号でなければならない。
	* `I_i`に`[A → α・, a]`が含まれていて、`A ≠ S'`ならば、`ACTION[i,a]`に“還元`A → α`”を入れる。
	* `I_i`に`[S' → S, $]`が含まれていれば、`ACTION[i,a]`に“受理”を入れる。
	* これらの結果によって、動作が競合する結果になれば、元の文法はLR(1)ではなく、このアルゴリズムによる構文解析器の作成は失敗である。
3. 状態`i`からの非終端記号Aによる`GOTO`を次のように計算する。すなわち、すべての`A`について、`GOTO(I_i, A) = I_j`であれば、`GOTO[i, A] = j`とする。
4. 規則2と3によって定義されなかったエントリは、すべて“エラー”とする。
5. `[S' → S, $]`を含む項集合に対応する状態を、構文解析器の初期状態とする。

## LALR構文解析表の効率の良い作成方法

* まず、LR(0)項集合またはLR(1)項集合は、カーネル項があれば、すなわち初期項`[S → ・S]`または`[S → ・S, $]`、あるいは生成規則の本体の先頭以外のところに点をもつ項だけを保持していれば、表現できる。
* LALR(1)のカーネル項は、LR(0)カーネル項から生成することができる。先読みについては、この後すぐに述べるが、伝搬と内部生成とによって作りだすことができる。
* LALR(1)のカーネル項からは、図4.40のCLOSURE関数を用いて各カーネルを閉じ、そのLALR(1)項集合を正準LR(1)項集合とみなして、アルゴリズム4.40を用いることによってLALR(1)構文解析表が作成できる。

注: 図4.40のCLOSURE関数とは、LR(1)のCLOSURE関数のこと

## 先読みの決定

```
入力 LR(0)項集合の中のカーネル項Kと文法記号X。
出力 GOTO(I,X)のカーネル項に対してIの項から内部生成される先読みと、GOTO(I,X)のカーネル項へ先読みを伝搬させるIの項。
```

```
for (Kに含まれる各項A → α・β) {
	J = CLOSURE({[A → α・β, #]});
	if ([B → γ・Xδ, a]がJに含まれていて、aが#ではない)
		先読みaは、GOTO(I,X)の項B → γX・δ用に内部生成されたものである。
	if ([B → γ・Xδ, #]がJに含まれている)
		先読みは、IのA → α・βからGOTO(I,X)のB → γX・δへ伝搬される。
}
```

## 英語

項はitem。項集合はset of items。項集合には通し番号を付ける。

```
input, output, stack, table = { action, goto }, driver program
input = { ..., $ }
marker($)
marker(#)
```
