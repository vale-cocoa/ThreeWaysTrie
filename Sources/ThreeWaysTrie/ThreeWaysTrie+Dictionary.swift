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
    public typealias Key = String
    
    public typealias Value = Value
    
    public init<S>(uniqueKeysWithValues keysAndValues: S) where S : Sequence, S.Element == (String, Value) {
        for (key, value) in keysAndValues {
            _check(key)
            root = _put(node: root, key: key, value: value, index: key.startIndex, uniquingKeysWith: { _, _ in preconditionFailure("Keys must be unique") })
        }
    }
    
    public init<S>(_ keysAndValues: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where S : Sequence, S.Element == (String, Value) {
        for (key, value) in keysAndValues {
            _check(key)
            root = try _put(node: root, key: key, value: value, index: key.startIndex, uniquingKeysWith: combine)
        }
    }
    
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
    public subscript(key: Key) -> Value? {
        get {
            _check(key)
            return _get(node: root, key: key, index: key.startIndex)?.value
        }
        
        mutating set {
            _check(key)
            _makeUnique()
            if let v = newValue {
                root = _put(node: root, key: key, value: v, index: key.startIndex, uniquingKeysWith: { _, latest in latest })
            } else {
                root = _remove(node: root, key: key, index: key.startIndex).nodeAfterRemoval
            }
        }
    }
    
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
        _rankForExistingKey(node: root, key: key, index: key.startIndex)
    }
    
    @discardableResult
    public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
        _check(key)
        _makeUnique()
        var oldValue: Value? = nil
        root = _put(node: root, key: key, value: value, index: key.startIndex, uniquingKeysWith: { older, latest in
            oldValue = older
            
            return latest
        })
        
        return oldValue
    }
    
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
    
    public mutating func removeAll() {
        root = nil
    }
    
}

// MARK: - Dictionary FP methods
extension ThreeWaysTrie {
    public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> ThreeWaysTrie<T> {
        let mappedRoot = try _mapValues(node: root, transform: transform)
        
        return ThreeWaysTrie<T>(root: mappedRoot)
    }
    
    public func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> ThreeWaysTrie<T> {
        let mappedRoot = try _compactMapValues(node: root, transform: transform)
        
        return ThreeWaysTrie<T>(root: mappedRoot)
    }
    
    public func filter(_ isIncluded: (Self.Element) throws -> Bool) rethrows -> Self
    {
        let filteredRoot = try _filter(node: root?._clone(), by: isIncluded)
        
        return Self(root: filteredRoot)
    }
    
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
