//
//  ThreeWaysTrie.swift
//  ThreeWaysTrie
//
//  Created by Valeriano Della Longa on 2021/09/02.
//  Copyright © 2021 Valeriano Della Longa. All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any
//  purpose with or without fee is hereby granted, provided that the above
//  copyright notice and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
//  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

import Foundation

/// A collection whose elements are key-value pairs, where each key is a non-empty `String` value, and stored elements are kept in sorted order by their key value.
///
/// A 3-ways trie is a type of symbol table, providing fast access to the entries it contains and fast prefix operations on its
/// keys. Each entry in the table is identified using its key, which is a non-empty `String` value. You use that key to retrieve
/// the corresponding value, which can be any object. Similar data types are also known as associated arrays.
///
/// Create a new trie by using a dictionary literal. A dictionary literal is a comma-separated list of key-value pairs, in which a
/// colon separates each key from its associated value, surrounded by square brackets. You can assign a dictionary literal to
/// a variable or constant or pass it to a function that expects a dictionary.
///
/// Here's how you would create a new trie via dictionary literal:
/// ```Swift
/// var wordsCount: ThreeWaysTrie<Int> = [
///     "she" : 1,
///     "sells" : 1,
///     "seashells" : 1,
///     "by" : 1,
///     "the" : 1,
///     "shoreline" : 1
/// ]
/// ```
///
/// To create a trie with no key-value pairs, either use an empty dictionary literal (`[:]`) or its `init()` method:
/// ```Swift
/// var emptyTrie: ThreeWaysTrie<Int> = [:]
/// var anotherEmptyTrie = ThreeWaysTrie<Int>()
/// ```
///
/// Non-empty `String` values must be used as trie's keys. An attempt to use an empty `String` value as a key will
/// trigger a run-time error.
public struct ThreeWaysTrie<Value> {
    internal var root: Node? = nil
    
    @usableFromInline
    internal mutating func _makeUnique() {
        if !isKnownUniquelyReferenced(&root) {
            root = root?._clone()
        }
    }
    
    /// Creates a new empty trie.
    ///
    /// - Returns:  A new, empty trie instance.
    /// - Complexity:   O(1)
    public init() {  }
    
}

// MARK: - Keys lookup operations
extension ThreeWaysTrie {
    /// Returns an array containing all the keys in the trie having the specified prefix.
    ///
    /// In the following example the returned array contains all keys starting with `se` that are stored inside
    /// the `wordsCount` trie:
    /// ```Swift
    /// let wordsCount: ThreeWaysTrie<Int> = [
    ///     "she" : 1,
    ///     "sells" : 1,
    ///     "seashells" : 1,
    ///     "by" : 1,
    ///     "the" : 1,
    ///     "shoreline" : 1
    /// ]
    /// let keysWithPrefixSE = trie.keys(with: "se")
    /// print(keysWithPrefixSE)
    /// // Prints: ["sells", "seashells"]
    /// ```
    ///
    /// In this other examples an empty `String` value is used as prefix, hence the returned array contains all keys
    /// inside `wordCount`:
    /// ```Swift
    /// let allKeys = wordsCount.keys(with: "")
    /// print(allKeys)
    /// // Prints: ["by", "seashells", "sells", "she", "shoreline", "the"]
    /// ```
    /// Use the `keys` property to obtain all keys stored in a trie instead of the previous example,
    /// that is such property has a better performance.
    ///
    /// - Parameter prefix: A `String` value representing the prefix of keys to look up in this trie.
    /// - Returns:  An array containing all keys stored in this trie with the specified prefix.
    /// - Complexity:   O(*k*) where *k* is the number of keys matching the specified prefix.
    public func keys(with prefix: String) -> [String] {
        var result: Array<String> = []
        guard !prefix.isEmpty else {
            _forEach(node: root, body: { result.append($0.key) })
            
            return result
        }
        
        weak var n = _get(node: root, key: prefix, index: prefix.startIndex)
        if n?.value != nil {
            result.append(prefix)
        }
        _forEach(node: n?.mid, prefix: prefix, body: {
            result.append($0.key)
        })
        
        return result
    }
    
    /// Returns an array containing all keys in this trie matching the specified pattern.
    /// The pattern **must not be empty** and can contain one or more `.` characters, which will be
    /// used as *wildcard* element in the lookup: that is stored keys characters at those positions in the pattern
    /// will match.
    ///
    /// The following example shows the usage of this method:
    /// ```Swift
    ///     let wordsCount: ThreeWaysTrie<Int> = [
    ///         "she" : 1,
    ///         "sells" : 1,
    ///         "seashells" : 1,
    ///         "by" : 1,
    ///         "the" : 1,
    ///         "shoreline" : 1
    ///     ]
    ///     var pattern = "s........"
    ///     var matchedKeys = wordsCount.keys(matching: pattern)
    ///     print(matchedKeys)
    ///     // Prints: ["seashells", "shoreline"]
    ///
    ///     pattern = ".he"
    ///     matchedKeys = wordsCount.keys(matching: pattern)
    ///     print(matchedKeys)
    ///     // Prints: ["she", "the"]
    ///
    ///     // Note that key must also match the lenght of the given pattern:
    ///     pattern = "se......."
    ///     matchedKeys = wordsCount.keys(matching: pattern)
    ///     print(matchedKeys)
    ///     // Prints: ["seashells"]
    ///     // key "sells" is not included in the result cause it matches the pattern only
    ///     // up to its lenght which is less than the lenght of the pattern:
    ///     // pattern:     se.......
    ///     // matching:    ^^^^^----
    ///     // key:         sells
    /// ```
    ///
    /// - Parameter pattern:    A string value that would be the pattern to match for returned keys.
    /// - Returns:  An array containing all stored keys matching the specified pattern.
    /// - Complexity:   O(*k*) where *k* is the number of keys matching the specified pattern.
    /// - Warning:  The specified `pattern` string value **must not be empty**,
    ///              otherwise a run-time error will occur.
    public func keys(matching pattern: String) -> [String] {
        guard
            !pattern.isEmpty
        else { return [] }
        
        var result: Array<String> = []
        _forEach(node: root, matching: pattern, at: pattern.startIndex, body: {
            result.append($0.0)
        })
        
        return result
    }
    
    /// Returns the sort position of the specified key in this trie.
    ///
    /// `ThreeWaysTrie` keeps its keys in sorted order, therefore is also possible to obtain the sort position of a key by
    ///  using the instance method `rank(of:)` and specifying as its `key` parameter a non-empty string value.
    ///  When the specified key matches a key already stored in the trie, then the result will be equal to the element index
    ///  in the trie, otherwise when the specified key doesn't matches exactly one already stored in the trie, then the
    ///  returned value is the index of the element with such key would be after being inserted in the trie.
    ///
    ///  The following example shows the usage of this method:
    /// ```Swift
    ///     let wordsCount: ThreeWaysTrie<Int> = [
    ///         "she" : 1,
    ///         "sells" : 1,
    ///         "seashells" : 1,
    ///         "by" : 1,
    ///         "the" : 1,
    ///         "shoreline" : 1
    ///     ]
    ///     print(wordsCount.rank(of: "she"))
    ///     // Prints: 3
    ///
    ///     print(wordsCount.rank(of: "biology"))
    ///     // Prints: 0
    ///
    ///     print(wordsCount.rank(of: "those"))
    ///     // Prints: 6
    /// ```
    ///
    /// - Parameter key:    A string value representing the key to look-up for its sort index.
    ///                     **Must not be empty**.
    /// - Returns:  A positive `Int` value in the range of `startIndex...endIndex`,
    ///             representing the index of the element with such key in the stored trie's
    ///             elements sorted by their key.
    /// - Complexity:   O(log *n*), where *n* is the lenght of the trie.
    /// - Warning:  The string value specified as `key` parameter **must not be empty**,
    ///             otherwise a run-time error will occur.
    public func rank(of key: String) -> Int {
        _check(key)
        
        return _rank(node: root, key: key, index: key.startIndex)
    }
    
    public func floor(_ key: Key) -> Key? {
        _check(key)
        
        return root?._floor(key: key, index: key.startIndex)
    }
    
    public func ceiling(_ key: Key) -> Key? {
        _check(key)
        
        return root?._ceiling(key: key, index: key.startIndex)
    }
    
}

// MARK: - Equatable conformance
extension ThreeWaysTrie: Equatable where Value: Equatable {
    public static func == (lhs: ThreeWaysTrie, rhs: ThreeWaysTrie) -> Bool {
        guard
            lhs.root !== rhs.root
        else { return true }
        
        guard lhs.count == rhs.count else { return false }
        
        for rank in 0..<lhs.count {
            let (lKey, lValue) = lhs._select(node: lhs.root, rank: rank)!
            let (rKey, rValue) = rhs._select(node: rhs.root, rank: rank)!
            guard
                lKey == rKey,
                lValue == rValue
            else { return false }
        }
        
        return true
    }
    
}

// MARK: - Hashable conformance
extension ThreeWaysTrie: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        for (key, value) in self {
            hasher.combine(key)
            hasher.combine(value)
        }
    }
    
}
