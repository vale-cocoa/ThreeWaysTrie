# ThreeWaysTrie

A symbol table collection —a.k.a. associative array or dictionary— with value semantics, which adopts nonempty `String` values as its keys and is generic over its `Value` type.
`ThreeWaysTrie` adopts 3 ways nodes storing `Characters` values from the keys it contains, thus working as a *trie* data structure for key based operations.
`ThreeWaysTrie<Value>` offers the same functionalities of a Swift `Dictionary<String, Value>`, but it also keeps its keys in sorted order. 
That is when iterating over the elements contained in `ThreeWaysTrie` instance, it will yield such elements is sorted order from the one with the smallest key to the one with the largest key. 

