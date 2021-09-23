//
//  ThreeWaysTrie+Collection.swift
//  ThreeWaysTrie
//
//  Created by Valeriano Della Longa on 2021/09/11.
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

extension ThreeWaysTrie: BidirectionalCollection, RandomAccessCollection {
    /// The position of a key-value pair in a trie.
    ///
    /// `ThreeWaysTrie` has two subscripting interfaces:
    ///
    /// 1. Subscripting with a key, yielding an optional value:
    ///
    ///        v = d[k]!
    ///
    /// 2. Subscripting with an index, yielding a key-value pair:
    ///
    ///        (k, v) = d[i]
    public typealias Index = Int
    
    @inline(__always)
    public var count: Int { root?.count ?? 0 }
        
    @inline(__always)
    public var isEmpty: Bool { root == nil }
    
    @inlinable
    public var startIndex: Int { 0 }
    
    @inline(__always)
    public var endIndex: Int { root?.count ?? 0 }
    
    @inline(__always)
    public var first: Element? {
        var result: Element? = nil
        root?._inOrderVisit({ stop, key, node in
            guard
                let v = node.value
            else { return }
            
            stop = true
            result = (key, v)
        })
        
        return result
    }
    
    @inline(__always)
    public var last: Element? {
        var result: Element? = nil
        root?._reverseInOrderVisit({ stop, key, node in
            guard
                let v = node.value
            else { return }
            
            stop = true
            result = (key, v)
        })
        
        return result
    }
    
    @inlinable
    public func index(after i: Int) -> Int {
        i + 1
    }
    
    @inlinable
    public func formIndex(after i: inout Int) {
        i += 1
    }
    
    @inlinable
    public func index(before i: Int) -> Int {
        i - 1
    }
    
    @inlinable
    public func formIndex(before i: inout Int) {
        i -= 1
    }
    
    /// Accesses the key-value pair at the specified position.
    ///
    /// This subscript takes an index into the trie, instead of a key, and
    /// returns the corresponding key-value pair as a tuple. When performing
    /// collection-based operations that return an index into a trie, use
    /// this subscript with the resulting value.
    ///
    /// For example, to find the key for a particular value in a trie, use
    /// the `firstIndex(where:)` method.
    ///
    ///     let countryCodes: ThreeWaysTrie<String> = [
    ///         "BR": "Brazil",
    ///         "GH": "Ghana",
    ///         "JP": "Japan"
    ///     ]
    ///     if let index = countryCodes.firstIndex(where: { $0.value == "Japan" }) {
    ///         print(countryCodes[index])
    ///         print("Japan's country code is '\(countryCodes[index].key)'.")
    ///     } else {
    ///         print("Didn't find 'Japan' as a value in the trie.")
    ///     }
    ///     // Prints "(key: "JP", value: "Japan")"
    ///     // Prints "Japan's country code is 'JP'."
    ///
    /// - Parameter position:   The position of the key-value pair to access.
    ///                         `position` must be a valid index of the trie
    ///                          and not equal to `endIndex`.
    /// - Returns:  A two-element tuple with the key and value corresponding to
    ///             `position`.
    ///
    /// - Complexity:   O(log *n*), where *n* is the lenght of the trie.
    ///                 Although that would be the worst-case scenario, commonly
    ///                 the complexity of the postion subscript operation would
    ///                 be close to O(1).
    public subscript(position: Int) -> Element {
        precondition(0..<endIndex ~= position, "Index out of bounds")
        
        return _select(node: root, rank: position)!
    }
    
    public func firstIndex(where predicate: (Element) throws -> Bool) rethrows -> Index? {
        var idx = -1
        var found = false
        try _traverse(traversal: .inOrder, { stop, key, node in
            guard
                let v = node.value
            else { return }
            
            idx += 1
            stop = try predicate((key, v))
            found = stop
        })
        
        return found ? idx : nil
    }
    
    public func lastIndex(where predicate: (Element) throws -> Bool) rethrows -> Index? {
        var idx = count
        var found = false
        try _traverse(traversal: .reverseInOrder, { stop, key, node in
            guard
                let v = node.value
            else { return }
            
            idx -= 1
            stop = try predicate((key, v))
            found = stop
        })
        
        return found ? idx : nil
    }
    
    /// Removes and returns the first key-value pair of the trie if the
    /// trie isn't empty.
    ///
    /// The first element of the trie is always the one with the smallest key;
    /// that is a trie keeps its elements sorted by its keys' values.
    ///
    /// - Returns:  The first key-value pair of the trie if the trie
    ///              is not empty; otherwise, `nil`.
    @inlinable
    public mutating func popFirst() -> Element? {
        guard !isEmpty else { return nil }
        
        return remove(at: startIndex)
    }
    
    /// Removes and returns the last key-value pair of the trie if the
    /// trie isn't empty.
    ///
    /// The last element of the trie is always the one with the largest key;
    /// that is a trie keeps its elements sorted by its keys' values.
    ///
    /// - Returns:  The last key-value pair of the trie if the trie
    ///              is not empty; otherwise, `nil`.
    @inlinable
    public mutating func popLast() -> Element? {
        guard !isEmpty else { return nil }
        
        return remove(at: endIndex - 1)
    }
    
}
