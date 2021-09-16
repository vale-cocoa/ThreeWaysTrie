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

public struct ThreeWaysTrie<Value> {
    internal var root: Node? = nil
    
    internal mutating func _makeUnique() {
        if !isKnownUniquelyReferenced(&root) {
            root = root?._clone()
        }
    }
    
    public init() {  }
    
}

// MARK: - Trie specific operations
extension ThreeWaysTrie {
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

// MARK: - Equatable confromance
extension ThreeWaysTrie: Equatable where Value: Equatable {
    public static func == (lhs: ThreeWaysTrie, rhs: ThreeWaysTrie) -> Bool {
        guard
            lhs.root !== rhs.root
        else { return true }
        
        guard lhs.count == rhs.count else { return false }
        
        for (lhsElement, rhsElement) in zip(lhs, rhs) where (lhsElement.key != rhsElement.key || lhsElement.value != rhsElement.value) {
            
            return false
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
