//
//  ThreeWaysTrie+Sequence.swift
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

extension ThreeWaysTrie: Sequence {
    // The element type of a trie: a tuple containing an individual
    /// key-value pair.
    public typealias Element = (key: Key, value: Value)
    
    public struct Iterator: IteratorProtocol {
        private let _trie: ThreeWaysTrie
        
        private var _nextElement: Element? = nil
        
        private var _rank = 0
        
        fileprivate init(_ trie: ThreeWaysTrie) {
            self._trie = trie
            self._getToNext()
        }
        
        public mutating func next() -> Element? {
            defer {
                _getToNext()
            }
            
            return _nextElement
        }
        
        fileprivate mutating func _getToNext() {
            defer {
                _rank += 1
            }
            _nextElement = _trie._select(node: _trie.root, rank: _rank)
        }
        
    }
    
    public var underestimatedCount: Int { root?.count ?? 0 }
    
    public func makeIterator() -> Iterator {
        Iterator(self)
    }
    
}

// MARK: - FP Sequence methods
extension ThreeWaysTrie {
    public func allSatisfy(_ predicate: (Self.Element) throws -> Bool) rethrows -> Bool {
        var satisfied = true
        try _traverse(traversal: .preOrder, { stop, key, node in
            guard
                let v = node.value
            else { return }
            
            satisfied = try predicate((key, v))
            stop = !satisfied
        })
        
        return satisfied
    }
    
    public func contains(where predicate: (Self.Element) throws -> Bool) rethrows -> Bool {
        var found = false
        try _traverse(traversal: .preOrder, { stop, key, node in
            guard
                let v = node.value
            else { return }
            
            found = try predicate((key, v))
            stop = found
        })
        
        return found
    }
    
    public func first(where predicate: (Self.Element) throws -> Bool) rethrows -> Element? {
        var matched: Element? = nil
        try _traverse(traversal: .inOrder, { stop, key, node in
            guard
                let v = node.value
            else { return }
            
            let element = (key: key, value: v)
            stop = try predicate(element)
            matched = stop ? element : nil
        })
        
        return matched
    }
    
    public func last(where predicate: (Self.Element) throws -> Bool) rethrows -> Element? {
        var matched: Element? = nil
        try _traverse(traversal: .reverseInOrder, { stop, key, node in
            guard
                let v = node.value
            else { return }
            
            let element = (key: key, value: v)
            stop = try predicate(element)
            matched = stop ? element : nil
        })
        
        return matched
    }
    
    public func forEach(_ body: (Self.Element) throws -> Void) rethrows {
        try _forEach(node: root, body: body)
    }
    
    public func map<T>(_ transform: (Self.Element) throws -> T) rethrows -> [T] {
        var result: Array<T> = []
        try _forEach(node: root, body: { try result.append(transform($0)) })
        
        return result
    }
    
    public func compactMap<ElementOfResult>(_ transform: (Self.Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
        var result: Array<ElementOfResult> = []
        try _forEach(node: root, body: {
            guard
                let transformed = try transform($0)
            else { return }
            
            result.append(transformed)
        })
        
        return result
    }
    
    public func flatMap<SegmentOfResult>(_ transform: (Self.Element) throws -> SegmentOfResult) rethrows -> [SegmentOfResult.Element] where SegmentOfResult : Sequence {
        var result: Array<SegmentOfResult.Element> = []
        try _forEach(node: root, body: {
            try result.append(contentsOf: transform($0))
        })
        
        return result
    }
    
    public func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, Self.Element) throws -> Result) rethrows -> Result {
        var result = initialResult
        try _forEach(node: root, body: {
            result = try nextPartialResult(result, $0)
        })
        
        return result
    }
    
    public func reduce<Result>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, Self.Element) throws -> ()) rethrows -> Result {
        var result = initialResult
        try _forEach(node: root, body: {
            try updateAccumulatingResult(&result, $0)
        })
        
        return result
    }
    
    public func filter(_ isIncluded: (Self.Element) throws -> Bool) rethrows -> [Self.Element] {
        var result: Array<Self.Element> = []
        try _forEach(node: root, body: {
            guard
                try isIncluded($0)
            else { return }
            
            result.append($0)
        })
        
        return result
    }
    
}
