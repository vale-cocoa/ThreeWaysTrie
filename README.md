# ThreeWaysTrie
A collection whose elements are key-value pairs, where each key is a non-empty `String` value, and stored elements are kept in sorted order by their key value.

A 3-ways trie is a type of symbol table, providing fast access to the entries it contains and fast prefix operations on its keys. Each entry in the table is identified using its key, which is a non-empty `String` value. You use that key to retrieve the corresponding value, which can be any object. Similar data types are also known as associated arrays.

Create a new trie by using a dictionary literal. A dictionary literal is a comma-separated list of key-value pairs, in which a colon separates each key from its associated value, surrounded by square brackets. You can assign a dictionary literal to a variable or constant or pass it to a function that expects a dictionary.

Here's how you would create a new trie via dictionary literal:
```Swift
    var wordsCount: ThreeWaysTrie<Int> = [
        "she" : 1,
        "sells" : 1,
        "seashells" : 1,
        "by" : 1,
        "the" : 1,
        "shoreline" : 1
    ]
```

To create a trie with no key-value pairs, either use an empty dictionary literal (`[:]`) or its `init()` method:
```Swift
    var emptyTrie: ThreeWaysTrie<Int> = [:]
    var anotherEmptyTrie = ThreeWaysTrie<Int>()
```

Non-empty `String` values must be used as trie's keys. An attempt to use an empty `String` value as a key will trigger a run-time error.


## Keys look-up operations
Aside for offering the same functionalities of a swift dictionary, a trie also offers specific and efficient look-up operations on its stored keys.

### Looking-up keys with a specific prefix via `keys(with:)` instance method
Use this method to look-up for keys in a trie instance that begin with the given `prefix` string parameter. 
The complexity for this operation is O(*k*) where *k* is the number of keys included in the trie matching the given prefix.

The following example show the usage of this method:
``` Swift
    let wordsCount: ThreeWaysTrie<Int> = [
        "she" : 1,
        "sells" : 1,
        "seashells" : 1,
        "by" : 1,
        "the" : 1,
        "shoreline" : 1
    ]
    let keysWithPrefixSE = trie.keys(with: "se")
    print(keysWithPrefixSE)
    // Prints: ["sells", "seashells"]
    
    let allKeys = wordsCount.keys(with: "")
    print(allKeys)
    // Prints: ["by", "seashells", "sells", "she", "shoreline", "the"]
```

Note that to obtain all keys in a trie instance it is better to use its `keys` property, which provides its result with a O(1) complexity. 

### Looking-up keys matching a pattern via `keys(matching:)` instance method 
`ThreeWaysTrie` instances can look-up for stored keys matching a *pattern* via `keys(matching:)` instance method.  
This method accepts a non-empty string value representing a *pattern* for looking up keys; such pattern can also contain the `.` character representing a *wildcard* element: that is when the given pattern contains one or more `.` character, then any key character at those positions will match the pattern.
Pattern matching on keys operation has a complexity of O(*k*), where *k* is the count of keys included in the trie matching the specified pattern.

The following example shows the usage of this method:
```Swift
    let wordsCount: ThreeWaysTrie<Int> = [
        "she" : 1,
        "sells" : 1,
        "seashells" : 1,
        "by" : 1,
        "the" : 1,
        "shoreline" : 1
    ]
    var pattern = "s........"
    var matchedKeys = wordsCount.keys(matching: pattern)
    print(matchedKeys)
    // Prints: ["seashells", "shoreline"]
    
    pattern = ".he"
    matchedKeys = wordsCount.keys(matching: pattern)
    print(matchedKeys)
    // Prints: ["she", "the"]
    
    // Note that key must also match the lenght of the given pattern:
    pattern = "se......."
    matchedKeys = wordsCount.keys(matching: pattern)
    print(matchedKeys)
    // Prints: ["seashells"]
    // key "sells" is not included in the result cause it matches the pattern only 
    // up to its lenght which is less than the lenght of the pattern:
    // pattern:     se.......
    // matching:    ^^^^^----
    // key:         sells
```

Note that specifying an empty pattern will trigger a run-time error.

### Getting the sort position of a key in the trie via `rank(of:)` instance method
`ThreeWaysTrie` keeps its keys in sorted order, therefore is also possible to obtain the sort position of a key by using the instance method `rank(of:)` and specifying as its `key` parameter a non-empty string value. When the specified key matches a key already stored in the trie, then the result will be equal to the element index in the trie, otherwise when the specified key doesn't matches exactly one already stored in the trie, then the returned value is the index of the element with such key would be after being inserted in the trie. 
Getting the *rank* of a key in a trie is an operation with O(log *n*) complexity, where *n* is the lenght of the trie. 

The following example shows the usage of this method:
```Swift
    let wordsCount: ThreeWaysTrie<Int> = [
        "she" : 1,
        "sells" : 1,
        "seashells" : 1,
        "by" : 1,
        "the" : 1,
        "shoreline" : 1
    ]
    print(wordsCount.rank(of: "she"))
    // Prints: 3
    
    print(wordsCount.rank(of: "biology"))
    // Prints: 0
    
    print(wordsCount.rank(of: "those"))
    // Prints: 6
```

Note that specifying an empty key will trigger a run-time error.

### Get the included key equal or immediately before a given one via `floor(key:)` instance method
The floor operation on a key can be done via the instance method `floor(key:)`, which accepts as its parameter a non-empty string value, and returns an optional value that would be the key included in the trie equal or immediately before the specified one. If such key doesn't exist in the trie, then this method will return `nil`.
The overall complexity of this operation is O(log *k*) where *k* is number of keys included in the trie less than or equal to the specified one.
In the following example the usage of this method is shown:
```Swift
        let wordsCount: ThreeWaysTrie<Int> = [
        "she" : 1,
        "sells" : 1,
        "seashells" : 1,
        "by" : 1,
        "the" : 1,
        "shoreline" : 1
    ]
    
    if let k = wordsCount.floor(key: "she") {
        print(k)
    } else {
        print("no included key is smaller than or equal to 'she'")
    }
    // Prints: "she"
    
    if let k = wordsCount.floor(key: "those") {
        print(k)
    } else {
        print("no included key is smaller than or equal to 'those'")
    }
    // Prints: "the"
    
    if let k = wordsCount.floor(key: "shore") {
        print(k)
    } else {
        print("No included key is smaller than or equal to 'shore'")
    }
    // Prints: "she"
    
    if let k = wordsCount.floor(key: "bio") {
        print(k)
    } else {
        print("no included key is smaller than or equal to 'bio'")
    }
    // Prints: "no included key is smaller than or equal to 'bio'"
```

Note that specifying an empty key will trigger a run-time error.

### Get the included key equal or immediately after a given one via `ceiling(key:)` instance method
The ceil operation on a key can be done via the instance method `ceiling(key:)`, which accepts as its parameter a non-empty string value, and returns an optional value that would be the key included in the trie equal or immediately after the specified one. If such key doesn't exist in the trie, then this method will return `nil`.
The overall complexity of this operation is O(log *k*) where *k* is number of keys included in the trie greater than or equal to the specified one.
In the following example the usage of this method is shown:
```Swift
        let wordsCount: ThreeWaysTrie<Int> = [
        "she" : 1,
        "sells" : 1,
        "seashells" : 1,
        "by" : 1,
        "the" : 1,
        "shoreline" : 1
    ]
    
    if let k = wordsCount.ceiling(key: "than") {
        print(k)
    } else {
        print("No included key is larger than or equal to 'than'")
    }
    // Prints: "the"
    
    if let k = wordsCount.ceiling(key: "anchor") {
        print(k)
    } else {
        print("No included key is larger than or equal to 'anchor'")
    }
    // Prints: "by"
    
    if let k = wordsCount.ceiling(key: "sells") {
        print(k)
    } else {
        print("No included key is larger than or equal to 'sells'")
    }
    // Prints: "sells"
    
    if let k = wordsCount.ceiling(key: "sea") {
        print(k)
    } else {
        print("No included key is larger than or equal to 'sea'")
    }
    // Prints: "seashells"
    
    if let k = wordsCount.ceiling(key: "thus") {
        print(k)
    } else {
        print("No included key is larger than or equal to 'thus'")
    }
    // Prints: "No included key is larger than or equal to 'thus'"
```

Note that specifying an empty key will trigger a run-time error.


## Dictionary operations
`ThreeWaysTrie` offers the same public interface of a Swift `Dictionary`, excepts for methods relating to the `capacity`: that is due of the way the underlaying buffer is designed (nodes), there is no contiguous memory buffer to reallocate/keep: 
* The `Dictionary` method `removeAll(keepingCapacity:)` for `ThreeWaysTrie` has the signature `removeAll()`, not accepting any parameter.
* The `Dictionary` method `reserveCapacity(_:)` is not present in the `ThreeWaysTrie` public interface. 
* The `Dictionary` property `capacity` doesn't exists in the `ThreeWaysTrie` public interface.
* The `Dictionary` initalizer `init(minimumCapacity:)` doesnt' exists in the `ThreeWaysTroe` public interface.
* The `Sequence` implementation of `withContiguousStorageIfAvailable(_:)` always returns a `nil` result.


## Collection conformance notes
`ThreeWaysTrie` conforms to Swift `Collection`, `BidirectionalCollection` and `RandomAccessCollection` protcols. There is a cavaet though for those protocols implementations: index based subscripts are not O(1) operations but rather have a O(log *n*) complexity (where *n* is the lenght of the trie instance).
`ThreeWaysTrie` adopts `Int` as its `Index` type, leveraging internally on the *rank* and *select* operations mutuated from ternary search trees. 
Thus even though the worst scenario for those operations are O(log *n*), their common performance is usually better, almost O(1).

Since the `Index` type is `Int`, indices can be moved at any distance and measuring the distance between them can be done with a O(1) complexity, plus the `count` property on `ThreeWaysTrie` also has a O(1) complexity. Therefore `RandomAccessCollection` requirements are fullfilled as well as `BidirectionalCollection` too are.

