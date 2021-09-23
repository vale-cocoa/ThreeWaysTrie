//
//  ThreeWaysTrie+Dictionary.swift
//  ThreeWaysTrie
//
//  Created by Valeriano Della Longa on 2021/09/10.
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

// MARK: - Initializers
extension ThreeWaysTrie: ExpressibleByDictionaryLiteral {
    /// The key type of a trie's element, a `String`.
    public typealias Key = String
    
    /// The value type of a trie's element.
    public typealias Value = Value
    
    /// Creates a new trie from the key-value pairs in the given sequence.
    ///
    /// You use this initializer to create a trie when you have a sequence
    /// of key-value tuples with unique keys. Passing a sequence with duplicate
    /// keys to this initializer results in a runtime error. If your
    /// sequence might have duplicate keys, use the
    /// `ThreeWaysTrie<Value>(_:uniquingKeysWith:)` initializer instead.
    /// Also passing a sequence containing one or more empty string values as keys
    /// results in a runtime error.
    ///
    /// The following example creates a new trie using an array of non-empty strings
    /// as the keys and integers as the values:
    ///
    ///     let digitWords = ["one", "two", "three", "four", "five"]
    ///     let wordToValue = ThreeWaysTrie(uniqueKeysWithValues: zip(digitWords, 1...5))
    ///     print(wordToValue["three"]!)
    ///     // Prints "3"
    ///     print(wordToValue)
    ///     // Prints "["five": 5, "four": 4, "one": 1, "three": 3, "two": 2]"
    ///
    /// - Parameter keysAndValues:  A sequence of key-value pairs to use for
    ///                             the new trie.
    ///                             **Every key in `keysAndValues` must be unique and not empty.**
    /// - Returns: A new trie initialized with the elements of `keysAndValues`.
    ///
    /// - Precondition: The sequence must not have duplicate keys nor empty keys.
    public init<S>(uniqueKeysWithValues keysAndValues: S) where S : Sequence, S.Element == (String, Value) {
        for (key, value) in keysAndValues {
            _check(key)
            root = _put(node: root, key: key, value: value, index: key.startIndex, uniquingKeysWith: { _, _ in preconditionFailure("Keys must be unique") })
        }
    }
    
    /// Creates a new trie from the key-value pairs in the given sequence,
    /// using a combining closure to determine the value for any duplicate keys.
    ///
    /// You use this initializer to create a trie when you have a sequence
    /// of key-value tuples that might have duplicate keys. As the trie is
    /// built, the initializer calls the `combine` closure with the current and
    /// new values for any duplicate keys. Pass a closure as `combine` that
    /// returns the value to use in the resulting trie The closure can
    /// choose between the two values, combine them to produce a new value, or
    /// even throw an error. The sequence must not contain any empty
    /// `String` value as key otherwise a runtime error occurs.
    ///
    /// The following example shows how to choose the first and last values for
    /// any duplicate keys:
    ///
    ///     let pairsWithDuplicateKeys = [("a", 1), ("b", 2), ("a", 3), ("b", 4)]
    ///
    ///     let firstValues = ThreeWaysTrie(pairsWithDuplicateKeys,
    ///                                  uniquingKeysWith: { (first, _) in first })
    ///     // ["a": 1, "b": 2]
    ///
    ///     let lastValues = ThreeWaysTrie(pairsWithDuplicateKeys,
    ///                                 uniquingKeysWith: { (_, last) in last })
    ///     // ["a": 3, "b": 4]
    ///
    /// - Parameters:
    ///   - keysAndValues:  A sequence of key-value pairs to use for the new trie.
    ///                     **Must not contain any empty string as key.**
    ///   - combine:    A closure that is called with the values for any duplicate
    ///                 keys that are encountered.
    ///                 The closure returns the desired value for the final trie.
    ///
    /// - Precondition: `keysAndValues` sequence must not contain any empty
    ///                 `String` value as key.
    public init<S>(_ keysAndValues: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where S : Sequence, S.Element == (String, Value) {
        for (key, value) in keysAndValues {
            _check(key)
            root = try _put(node: root, key: key, value: value, index: key.startIndex, uniquingKeysWith: combine)
        }
    }
    
    /// Creates a new trie whose keys are the groupings returned by the
    /// given closure and whose values are arrays of the elements that returned
    /// each key.
    ///
    /// The arrays in the "values" position of the new trie each contain at
    /// least one element, with the elements in the same order as the source
    /// sequence. The given closure must return non-empty string values otherwise
    /// a runtime error occurs.
    ///
    /// The following example declares an array of names, and then creates a
    /// trie from that array by grouping the names by first letter:
    ///
    ///     let students = ["Kofi", "Abena", "Efua", "Kweku", "Akosua"]
    ///     let studentsByLetter = ThreeWaysTrie(grouping: students, by: { $0.first! })
    ///     // ["A": ["Abena", "Akosua"], "E": ["Efua"], "K": ["Kofi", "Kweku"]]
    ///
    /// The new `studentsByLetter` trie has three entries, with students'
    /// names grouped by the keys `"E"`, `"K"`, and `"A"`.
    ///
    /// - Parameters:
    ///   - values: A sequence of values to group into a trie.
    ///   - keyForValue:    A closure that returns a key for each element in
    ///                     `values`. **Must not return empty string values**.
    ///
    /// - Precondition: The given closure `keyForValue` must return non-empty
    ///                 `String` values.
    public init<S>(grouping values: S, by keyForValue: (S.Element) throws -> String) rethrows where Value == [S.Element], S : Sequence {
        for value in values {
            let key = try keyForValue(value)
            _check(key)
            root = _put(node: root, key: key, value: [value], index: key.startIndex, uniquingKeysWith: { $0 + $1 })
        }
    }
    
    
    public init(dictionaryLiteral elements: (String, Value)...) {
        self.init(uniqueKeysWithValues: elements)
    }
    
}

// MARK: - Key based subscripts and key/index based operations
extension ThreeWaysTrie {
    /// Accesses the value associated with the given key for reading and writing.
    ///
    /// This *key-based* subscript returns the value for the given key if the key
    /// is found in the trie, or `nil` if the key is not found.
    ///
    /// The following example creates a new trie and prints the value of a
    /// key found in the dictionary (`"Coral"`) and a key not found in the
    /// trie (`"Cerise"`).
    ///
    ///     var hues: ThreeWaysTrie<Int> = [
    ///         "Heliotrope": 296,
    ///         "Coral": 16,
    ///         "Aquamarine": 156
    ///     ]
    ///     print(hues["Coral"])
    ///     // Prints "Optional(16)"
    ///     print(hues["Cerise"])
    ///     // Prints "nil"
    ///
    /// When you assign a value for a key and that key already exists, the
    /// trie overwrites the existing value. If the trie doesn't contain the key,
    /// the key and value are added as a new key-value pair.
    ///
    /// Here, the value for the key `"Coral"` is updated from `16` to `18` and a
    /// new key-value pair is added for the key `"Cerise"`.
    ///
    ///     hues["Coral"] = 18
    ///     print(hues["Coral"])
    ///     // Prints "Optional(18)"
    ///
    ///     hues["Cerise"] = 330
    ///     print(hues["Cerise"])
    ///     // Prints "Optional(330)"
    ///
    /// If you assign `nil` as the value for the given key, the trie
    /// removes that key and its associated value.
    ///
    /// In the following example, the key-value pair for the key `"Aquamarine"`
    /// is removed from the trie by assigning `nil` to the key-based
    /// subscript.
    ///
    ///     hues["Aquamarine"] = nil
    ///     print(hues)
    ///     // Prints "["Coral": 18, "Heliotrope": 296, "Cerise": 330]"
    ///
    /// - Parameter key: The key to find in the trie.
    ///
    /// - Returns:  The value associated with `key` if `key` is in the trie;
    ///             otherwise, `nil`.
    public subscript(key: Key) -> Value? {
        get {
            _check(key)
            return _get(node: root, key: key, index: key.startIndex)?.value
        }
        
        mutating set {
            _check(key)
            _makeUnique()
            if let v = newValue {
                root = _put(node: root, key: key, value: v, index: key.startIndex, uniquingKeysWith: { $1 })
            } else {
                root = _remove(node: root, key: key, index: key.startIndex).nodeAfterRemoval
            }
        }
    }
    
    /// Accesses the value with the given key. If the trie doesn't contain
    /// the given key, accesses the provided default value as if the key and
    /// default value existed in the trie.
    ///
    /// Use this subscript when you want either the value for a particular key
    /// or, when that key is not present in the trie, a default value. This
    /// example uses the subscript with a word count value to use in case
    /// a HTTP word is not included in the trie:
    ///
    ///     var wordsCount: ThreeWaysTrie<Int> = [
    ///      "she" : 1,
    ///      "sells" : 1,
    ///      "seashells" : 1,
    ///      "by" : 1,
    ///     "the" : 1,
    ///     "shoreline" : 1
    ///     ]
    ///     let words = ["she", "sells", "thus"]
    ///     for word in words {
    ///         let countOfWord = wordsCount[word, default: 0]
    ///         print("word: \(word), occurences: \(countOfWords)")
    ///     }
    ///     // Prints "word: she, occurences: 1"
    ///     // Prints "word: sells, occurences: 1"
    ///     // Prints "word: thus, occurences: 0"
    ///
    /// When a trie's `Value` type has value semantics, you can use this
    /// subscript to perform in-place operations on values in the trie.
    /// The following example shows such usage:
    ///
    ///     let words = "she sells seashells by the shoreline"
    ///     var wordsCount = ThreeWaysTrie<Int>()
    ///     for word in words.components(separatedBy: " ") {
    ///         wordsCount[word, default: 0] += 1
    ///     }
    ///     // wordsCount == ["by": 1, "seashells": 1, "sells": 1, "shoreline": 1, ...]
    ///
    /// When `wordsCount[word, defaultValue: 0] += 1` is executed with a
    /// value of `word` that isn't already a key in `wordsCount`, the
    /// specified default value (`0`) is returned from the subscript,
    /// incremented, and then added to the trie under that key.
    ///
    /// - Note: Do not use this subscript to modify trie values if the
    ///         trie's `Value` type is a class. In that case, the default value
    ///         and key are not written back to the trie after an operation.
    ///
    /// - Parameters:
    ///   - key: The key the look up in the trie.
    ///   - defaultValue: The default value to use if `key` doesn't exist in the trie.
    ///
    /// - Returns: The value associated with `key` in the trie; otherwise, `defaultValue`.
    public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        get {
            _check(key)
            
            return _get(node: root, key: key, index: key.startIndex)?.value ?? defaultValue()
            
        }
        _modify {
            _check(key)
            _makeUnique()
            var other = Self()
            (self, other) = (other, self)
            defer {
                (self, other) = (other, self)
            }
            let (newRoot, finalNode) = other._get(node: other.root, key: key, index: key.startIndex, defaultValue: defaultValue)
            other.root = newRoot
            yield(&finalNode.value!)
        }
    }
    
    public func index(forKey key: Key) -> Int? {
        _check(key)
        
        return _rankForExistingKey(node: root, key: key, index: key.startIndex)
    }
    
    /// Updates the value stored in the trie for the given key, or adds a
    /// new key-value pair if the key does not exist.
    ///
    /// Use this method instead of key-based subscripting when you need to know
    /// whether the new value supplants the value of an existing key. If the
    /// value of an existing key is updated, `updateValue(_:forKey:)` returns
    /// the original value.
    ///
    ///     var hues: ThreeWaysTrie<Int> = [
    ///         "Heliotrope": 296,
    ///         "Coral": 16,
    ///         "Aquamarine": 156
    ///     ]
    ///
    ///     if let oldValue = hues.updateValue(18, forKey: "Coral") {
    ///         print("The old value of \(oldValue) was replaced with a new one.")
    ///     }
    ///     // Prints "The old value of 16 was replaced with a new one."
    ///
    /// If the given key is not present in the trie, this method adds the
    /// key-value pair and returns `nil`.
    ///
    ///     if let oldValue = hues.updateValue(330, forKey: "Cerise") {
    ///         print("The old value of \(oldValue) was replaced with a new one.")
    ///     } else {
    ///         print("No value was found in the dictionary for that key.")
    ///     }
    ///     // Prints "No value was found in the dictionary for that key."
    ///
    /// The given key must be an non-empty string value, otherwise a runtime error occurs.
    ///
    /// - Parameters:
    ///   - value: The new value to add to the trie.
    ///   - key:    The key to associate with `value`. If `key` already exists in
    ///             the trie, `value` replaces the existing associated value.
    ///             If `key` isn't already a key of the trie,
    ///             the `(key, value)` pair is added.
    ///             **Must not be empty**.
    /// - Returns:  The value that was replaced, or `nil` if a new key-value pair
    ///             was added.
    ///
    /// - Precondition: `key` must not be an empty `String` value.
    @discardableResult
    public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
        _check(key)
        _makeUnique()
        var oldValue: Value? = nil
        root = _put(node: root, key: key, value: value, index: key.startIndex, uniquingKeysWith: {
            oldValue = $0
            
            return $1
        })
        
        return oldValue
    }
    
    /// Removes the given key and its associated value from the trie.
    ///
    /// If the key is found in the trie, this method returns the key's
    /// associated value. On removal, this method invalidates all indices with
    /// respect to the trie.
    ///
    ///     var hues: ThreeWaysTrie<Int> = [
    ///         "Heliotrope": 296,
    ///         "Coral": 16,
    ///         "Aquamarine": 156
    ///     ]
    ///     if let value = hues.removeValue(forKey: "Coral") {
    ///         print("The value \(value) was removed.")
    ///     }
    ///     // Prints "The value 16 was removed."
    ///
    /// If the key isn't found in the trie, `removeValue(forKey:)` returns
    /// `nil`.
    ///
    ///     if let value = hues.removeValue(forKey: "Cerise") {
    ///         print("The value \(value) was removed.")
    ///     } else {
    ///         print("No value found for that key.")
    ///     }
    ///     // Prints "No value found for that key.""
    ///
    /// The given key must not be an empty string, otherwise a runtime error occurs.
    ///
    /// - Parameter key:    The key to remove along with its associated value.
    ///                     **Must be a non-empty string**.
    ///
    /// - Returns:  The value that was removed, or `nil` if the key was not
    ///             present in the trie.
    ///
    /// - Complexity:   O(log *n*), where *n* is the number of key-value pairs in the
    ///                 trie.
    @discardableResult
    mutating func removeValue(forKey key: Key) -> Value? {
        _check(key)
        _makeUnique()
        let (newRoot, oldValue) = _remove(node: root, key: key, index: key.startIndex)
        defer {
            root = newRoot
        }
        
        return oldValue
    }
    
    /// Removes and returns the key-value pair at the specified index.
    ///
    /// Calling this method invalidates any existing indices for use with this
    /// trie.
    ///
    /// - Parameter index: The position of the key-value pair to remove. `index`
    ///   must be a valid index of the trie, and must not equal the
    ///   trie's end index.
    /// - Returns: The key-value pair that correspond to `index`.
    ///
    /// - Complexity:   O(log *n*), where *n* is the number of key-value pairs in the trie.
    @discardableResult
    public mutating func remove(at index: Int) -> Element {
        precondition(0..<endIndex ~= index, "Index out of bounds")
        _makeUnique()
        let (rootAfterRemoval, removedElement) = _removeElementAt(node: root, rank: index)
        defer {
            root = rootAfterRemoval
        }
        
        return removedElement!
    }
    
    /// Removes all key-value pairs from the trie.
    ///
    /// Calling this method invalidates all indices with respect to the
    /// trie.
    ///
    /// - Complexity: O(1).
    public mutating func removeAll() {
        root = nil
    }
    
}

// MARK: - Dictionary FP methods
extension ThreeWaysTrie {
    /// Returns a new trie containing the keys of this trie with the
    /// values transformed by the given closure.
    ///
    /// - Parameter transform:  A closure that transforms a value. `transform`
    ///                         accepts each value of the trie as its parameter and
    ///                         returns a transformed value of the same or
    ///                         of a different type.
    /// - Returns:  A trie containing the keys and transformed values of this trie.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the trie.
    public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> ThreeWaysTrie<T> {
        let mappedRoot = try _mapValues(node: root, transform: transform)
        
        return ThreeWaysTrie<T>(root: mappedRoot)
    }
    
    /// Returns a new trie containing only the key-value pairs that have
    /// non-`nil` values as the result of transformation by the given closure.
    ///
    /// Use this method to receive a trie with non-optional values when
    /// your transformation produces optional values.
    ///
    /// In this example, note the difference in the result of using `mapValues`
    /// and `compactMapValues` with a transformation that returns an optional
    /// `Int` value.
    ///
    ///     let data: ThreeWaysTrie<String> = ["a": "1", "b": "three", "c": "///4///"]
    ///
    ///     let m: ThreeWaysTrie<Int?> = data.mapValues { str in Int(str) }
    ///     // ["a": Optional(1), "b": nil, "c": nil]
    ///
    ///     let c: ThreeWaysTrie<Int> = data.compactMapValues { str in Int(str) }
    ///     // ["a": 1]
    ///
    /// - Parameter transform:  A closure that transforms a value. `transform`
    ///                         accepts each value of the trie as its parameter and returns an
    ///                         optional transformed value of the same or of a different type.
    /// - Returns:  A trie containing the keys and non-`nil` transformed values of this trie.
    ///
    /// - Complexity:   O(*m* + *n*), where *n* is the length of the original trie
    ///                 and *m* is the length of the resulting trie.
    public func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> ThreeWaysTrie<T> {
        let mappedRoot = try _compactMapValues(node: root, transform: transform)
        
        return ThreeWaysTrie<T>(root: mappedRoot)
    }
    
    /// Returns a new trie containing the key-value pairs of the trie
    /// that satisfy the given predicate.
    ///
    /// - Parameter isIncluded: A closure that takes a key-value pair as its
    ///   argument and returns a Boolean value indicating whether the pair
    ///   should be included in the returned trie.
    /// - Returns: A trie of the key-value pairs that `isIncluded` allows.
    public func filter(_ isIncluded: (Self.Element) throws -> Bool) rethrows -> Self
    {
        let filteredRoot = try _filter(node: root?._clone(), by: isIncluded)
        
        return Self(root: filteredRoot)
    }
    
    /// Merges the given trie into this trie, using a combining
    /// closure to determine the value for any duplicate keys.
    ///
    /// Use the `combine` closure to select a value to use in the updated
    /// trie, or to combine existing and new values. As the key-values
    /// pairs in `other` are merged with this trie, the `combine` closure
    /// is called with the current and new values for any duplicate keys that
    /// are encountered.
    ///
    /// This example shows how to choose the current or new values for any
    /// duplicate keys:
    ///
    ///     var trie: ThreeWaysTrie<Int> = ["a": 1, "b": 2]
    ///
    ///     // Keeping existing value for key "a":
    ///     trie.merge(["a": 3, "c": 4]) { (current, _) in current }
    ///     // ["a": 1, "b": 2, "c": 4]
    ///
    ///     // Taking the new value for key "a":
    ///     trie.merge(["a": 5, "d": 6]) { (_, new) in new }
    ///     // ["a": 5, "b": 2, "c": 4, "d": 6]
    ///
    /// - Parameters:
    ///   - other:  A trie to merge.
    ///   - combine:    A closure that takes the current and new values for any
    ///                 duplicate keys.
    ///                 The closure returns the desired value for the final trie.
    public mutating func merge(_ other: Self, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows {
        guard
            other.root != nil
        else { return }
        
        guard
            root != nil
        else {
            root = other.root
            
            return
        }
        
        _makeUnique()
        try other._forEach(node: other.root, body: { otherElement in
            root = try _put(node: root, key: otherElement.key, value: otherElement.value, index: otherElement.key.startIndex, uniquingKeysWith: combine)
        })
    }
    
    /// Merges the key-value pairs in the given sequence into the trie,
    /// using a combining closure to determine the value for any duplicate keys.
    ///
    /// Use the `combine` closure to select a value to use in the updated
    /// trie, or to combine existing and new values. As the key-value
    /// pairs are merged with the trie, the `combine` closure is called
    /// with the current and new values for any duplicate keys that are
    /// encountered.
    ///
    /// This example shows how to choose the current or new values for any
    /// duplicate keys:
    ///
    ///     var trie: ThreeWaysTrie = ["a": 1, "b": 2]
    ///
    ///     // Keeping existing value for key "a":
    ///     trie.merge(zip(["a", "c"], [3, 4])) { (current, _) in current }
    ///     // ["a": 1, "b": 2, "c": 4]
    ///
    ///     // Taking the new value for key "a":
    ///     trie.merge(zip(["a", "d"], [5, 6])) { (_, new) in new }
    ///     // ["a": 5, "b": 2, "c": 4, "d": 6]
    ///
    /// The given sequence must contain non-empty `String` values as keys, otherwise a runtime error occurs.
    ///
    /// - Parameters:
    ///   - other:  A sequence of key-value pairs. **Must not contain empty key string values**.
    ///   - combine:    A closure that takes the current and new values for any
    ///                 duplicate keys. The closure returns the desired value for the final trie.
    ///
    /// - Precondition: `other` sequence's keys values must be non-empty `String` values.
    public mutating func merge<S>(_ other: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where S : Sequence, S.Element == (Key, Value) {
        guard
            root != nil
        else {
            self = try Self.init(other, uniquingKeysWith: combine)
            return
        }
        
        let done: Bool = try other.withContiguousStorageIfAvailable({ buffer in
            guard
                !buffer.isEmpty
            else { return true }
            
            self._makeUnique()
            for i in 0..<buffer.count {
                let (newKey, newValue) = buffer.baseAddress!.advanced(by: i).pointee
                self.root = try self._put(node: self.root, key: newKey, value: newValue, index: newKey.startIndex, uniquingKeysWith: combine)
            }
            
            return true
        }) ?? false
        guard
            !done
        else { return }
        
        var otherIter = other.makeIterator()
        guard
            let (firstKey, firstValue) = otherIter.next()
        else { return }
        
        _makeUnique()
        root = try _put(node: root, key: firstKey, value: firstValue, index: firstKey.startIndex, uniquingKeysWith: combine)
        while let (otherKey, otherValue) = otherIter.next() {
            root = try _put(node: root, key: otherKey, value: otherValue, index: otherKey.startIndex, uniquingKeysWith: combine)
        }
    }
    
    /// Creates a trie by merging the given trie into this
    /// trie, using a combining closure to determine the value for
    /// duplicate keys.
    ///
    /// Use the `combine` closure to select a value to use in the returned
    /// trie, or to combine existing and new values. As the key-value
    /// pairs in `other` are merged with this trie, the `combine` closure
    /// is called with the current and new values for any duplicate keys that
    /// are encountered.
    ///
    /// This example shows how to choose the current or new values for any
    /// duplicate keys:
    ///
    ///     let trie: ThreeWaysTrie<Int> = ["a": 1, "b": 2]
    ///     let otherTrie: ThreeWaysTrie = ["a": 3, "b": 4]
    ///
    ///     let keepingCurrent = trie.merging(otherTrie)
    ///           { (current, _) in current }
    ///     // ["a": 1, "b": 2]
    ///     let replacingCurrent = trie.merging(otherTrie)
    ///           { (_, new) in new }
    ///     // ["a": 3, "b": 4]
    ///
    /// - Parameters:
    ///   - other:  A trie to merge.
    ///   - combine:    A closure that takes the current and new values for any
    ///                 duplicate keys.
    ///                 The closure returns the desired value for the final trie.
    ///
    /// - Returns:  A new trie with the combined keys and values of this
    ///             trie and `other`.
    public func merging(_ other: Self, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> Self {
        guard
            root != nil
        else { return other }
        
        guard
            other.root != nil
        else { return self }
        
        var (merged, source) = root!.count > other.root!.count ? (Self(root: self.root?._clone()), other) : (Self(root: other.root?._clone()), self)
        try source._forEach(node: source.root, body: { otherElement in
            merged.root = try merged._put(node: merged.root, key: otherElement.key, value: otherElement.value, index: otherElement.key.startIndex, uniquingKeysWith: combine)
        })
        
        return merged
    }
    
    /// Creates a trie by merging key-value pairs in a sequence into the
    /// trie, using a combining closure to determine the value for
    /// duplicate keys.
    ///
    /// Use the `combine` closure to select a value to use in the returned
    /// trie, or to combine existing and new values. As the key-value
    /// pairs are merged with the trie, the `combine` closure is called
    /// with the current and new values for any duplicate keys that are
    /// encountered.
    ///
    /// This example shows how to choose the current or new values for any
    /// duplicate keys:
    ///
    ///     let trie: ThreeWaysTrie<Int> = ["a": 1, "b": 2]
    ///     let newKeyValues = zip(["a", "b"], [3, 4])
    ///
    ///     let keepingCurrent = trie.merging(newKeyValues) { (current, _) in current }
    ///     // ["a": 1, "b": 2]
    ///     let replacingCurrent = trie.merging(newKeyValues) { (_, new) in new }
    ///     // ["a": 3, "b": 4]
    ///
    /// The given sequence must contain as keys non-empty `String` values, otherwise a runtime error occurs.
    ///
    /// - Parameters:
    ///   - other:  A sequence of key-value pairs. **Must not contain empty string values as keys**.
    ///   - combine:    A closure that takes the current and new values for any
    ///                 duplicate keys.
    ///                 The closure returns the desired value for the final trie.
    ///
    /// - Returns:  A new trie with the combined keys and values of this
    ///             trie and `other`.
    ///
    /// - Precondition: `other` must contain only non-empty `String` values as keys.
    public func merging<S>(_ other: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> Self where S : Sequence, S.Element == (Key, Value) {
        guard
            root != nil
        else {
            return try Self(other, uniquingKeysWith: combine)
        }
        
        var merged = self
        let done: Bool = try other.withContiguousStorageIfAvailable({ buffer in
            guard
                !buffer.isEmpty
            else { return true }
            
            merged._makeUnique()
            for i in 0..<buffer.count {
                let (otherKey, otherValue) = buffer.baseAddress!.advanced(by: i).pointee
                merged.root = try merged._put(node: merged.root, key: otherKey, value: otherValue, index: otherKey.startIndex, uniquingKeysWith: combine)
            }
            
            return true
        }) ?? false
        
        if !done {
            var otherIterator = other.makeIterator()
            if let (firstKey, firstValue) = otherIterator.next() {
                merged._makeUnique()
                merged.root = try merged._put(node: merged.root, key: firstKey, value: firstValue, index: firstKey.startIndex, uniquingKeysWith: combine)
                while let (otherKey, otherValue) = otherIterator.next() {
                    merged.root = try merged._put(node: merged.root, key: otherKey, value: otherValue, index: otherKey.startIndex, uniquingKeysWith: combine)
                }
            }
        }
        
        return merged
    }
    
}

// MARK: - private helpers
extension ThreeWaysTrie {
    fileprivate init(root: Node?) {
        self.root = root
    }
    
    @usableFromInline
    internal func _check(_ key: String) {
        precondition(!key.isEmpty, "Empty string is not allowed as key")
    }
    
}
