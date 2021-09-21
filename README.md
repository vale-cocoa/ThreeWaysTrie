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
The complexity for this operation is O(*k*) where *k* is the number of keys matching the given prefix.

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
Pattern matching on keys operation has a complexity of O(*k*), where *k* is the count of keys matching the specified pattern.

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
