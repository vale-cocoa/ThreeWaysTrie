//
//  ThreeWaysTrie+NodeOperations.swift
//  ThreeWaysTrie
//
//  Created by Valeriano Della Longa on 2021/09/06.
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

// MARK: - CRUD operations
extension ThreeWaysTrie {
    internal func _get(node: Node?, key: String, index: String.Index) -> Node? {
        guard
            let nodeChar = node?.char
        else { return nil }
        
        let c = key[index]
        if c < nodeChar {
            
            return _get(node: node?.left, key: key, index: index)
        } else if c > nodeChar {
           
            return _get(node: node?.right, key: key, index: index)
        } else if index < key.index(before: key.endIndex) {
            
            return _get(node: node?.mid, key: key, index: key.index(after: index))
        } else {
            
            return node
        }
        
    }
    
    internal func _get(node: Node?, key: String, index: String.Index, defaultValue: () -> Value) -> (newRoot: Node, finalNode: Node) {
        let c = key[index]
        let newRoot = node ?? Node(char: c)
        let finalNode: Node!
        if c < newRoot.char {
            let result = _get(node: newRoot.left, key: key, index: index, defaultValue: defaultValue)
            newRoot.left = result.newRoot
            finalNode = result.finalNode
        } else if c > newRoot.char {
            let result = _get(node: newRoot.right, key: key, index: index, defaultValue: defaultValue)
            newRoot.right = result.newRoot
            finalNode = result.finalNode
        } else if index < key.index(before: key.endIndex) {
            let result = _get(node: newRoot.mid, key: key, index: key.index(after: index), defaultValue: defaultValue)
            newRoot.mid = result.newRoot
            finalNode = result.finalNode
        } else {
            if newRoot.value == nil {
                newRoot.value = defaultValue()
            }
            finalNode = newRoot
        }
        newRoot._updateCount()
        
        return (newRoot, finalNode)
    }
    
    internal func _put(node: Node?, key: String, value: Value, index: String.Index, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> Node {
        let c = key[index]
        let n = node ?? Node(char: c)
        if c < n.char {
            n.left = try _put(node: n.left, key: key, value: value, index: index, uniquingKeysWith: combine)
        } else if c > n.char {
            n.right = try _put(node: n.right, key: key, value: value, index: index, uniquingKeysWith: combine)
        } else if index < key.index(before: key.endIndex) {
            n.mid = try _put(node: n.mid, key: key, value: value, index: key.index(after: index), uniquingKeysWith: combine)
        } else {
            if let oldValue = n.value {
                n.value = try combine(oldValue, value)
            } else {
                n.value = value
            }
        }
        n._updateCount()
        
        return n
    }
    
    internal func _remove(node: Node?, key: String, index: String.Index) -> (nodeAfterRemoval: Node?, oldValue: Value?) {
        guard
            let nodeChar = node?.char
        else { return (nil, nil) }
        
        var oldValue: Value? = nil
        let c = key[index]
        
        if c < nodeChar {
            let newLeftAndOldValue = _remove(node: node?.left, key: key, index: index)
            node?.left = newLeftAndOldValue.nodeAfterRemoval
            oldValue = newLeftAndOldValue.oldValue
        } else if c > nodeChar {
            let newRightAndOldValue = _remove(node: node?.right, key: key, index: index)
            node?.right = newRightAndOldValue.nodeAfterRemoval
            oldValue = newRightAndOldValue.oldValue
        } else if index < key.index(before: key.endIndex) {
            let newMidAndOldValue = _remove(node: node?.mid, key: key, index: key.index(after: index))
            node?.mid = newMidAndOldValue.nodeAfterRemoval
            oldValue = newMidAndOldValue.oldValue
        } else {
            oldValue = node?.value
            node?.value = nil
        }
        node?._updateCount()
        
        return ((node?._isEmpty == false ? node : nil), oldValue)
    }
    
    internal func _removeElementAt(node: Node?, rank: Int) -> (nodeAfterRemoval: Node?, removedElement: Element?) {
        guard
            let nodeChar = node?.char
        else { return (nil, nil) }
        
        var removedElement: Element? = nil
        let leftCount = node?.left?.count ?? 0
        if leftCount > rank {
            let lResult = _removeElementAt(node: node?.left, rank: rank)
            node?.left = lResult.nodeAfterRemoval
            removedElement = lResult.removedElement
        } else {
            let r = node?.value != nil ? 1 : 0
            let midCount = node?.mid?.count ?? 0
            if rank >= leftCount + midCount + r {
                let localRank = rank - leftCount - midCount - r
                let rResult = _removeElementAt(node: node?.right, rank: localRank)
                node?.right = rResult.nodeAfterRemoval
                removedElement = rResult.removedElement
            } else {
                let prefix = String(nodeChar)
                let localRank = rank - leftCount - r
                let midResult = _removeElementAt(node: node?.mid, rank: localRank)
                if let (midPrefix, midValue) = midResult.removedElement {
                    removedElement = (prefix + midPrefix, midValue)
                    node?.mid = midResult.nodeAfterRemoval
                } else if let v = node?.value {
                    removedElement = (prefix, v)
                    node?.value = nil
                }
            }
        }
        node?._updateCount()
        
        return (node?._isEmpty == false ? node : nil, removedElement)
    }
    
}

// MARK: - rank operations
extension ThreeWaysTrie {
    internal func _rank(node: Node?, key: String, index: String.Index) -> Int {
        guard
            let nodeChar = node?.char
        else { return 0 }
        
        let c = key[index]
        if c < nodeChar {
            
            return _rank(node: node?.left, key: key, index: index)
        } else {
            if c > nodeChar {
                let r = (node?.value != nil ? 1 : 0) + (node?.mid?.count ?? 0) + (node?.left?.count ?? 0)
                
                return r + _rank(node: node?.right, key: key, index: index)
            } else if index < key.index(before: key.endIndex) {
                let r = (node?.value != nil ? 1 : 0) + (node?.left?.count ?? 0)
                
                return r + _rank(node: node?.mid, key: key, index: key.index(after: index))
            } else {
                
                return node?.left?.count ?? 0
            }
        }
    }
    
    internal func _rankForExistingKey(node: Node?, key: Key, index: String.Index) -> Int? {
        guard
            let nodeChar = node?.char
        else { return nil }
        
        let c = key[index]
        if c < nodeChar {
            
            return _rankForExistingKey(node: node?.left, key: key, index:index)
        } else if
            c > nodeChar,
            let rRank = _rankForExistingKey(node: node?.right, key: key, index: index)
        {
            let r = (node?.value != nil ? 1 : 0) + (node?.mid?.count ?? 0) + (node?.left?.count ?? 0)
            
            return r + rRank
        } else if
            index < key.index(before: key.endIndex),
            let mRank = _rankForExistingKey(node: node?.mid, key: key, index: key.index(after: index))
        {
            let r = (node?.value != nil ? 1 : 0) + (node?.left?.count ?? 0)
            
            return r + mRank
        } else {
            
            return node?.value != nil ? (node?.left?.count ?? 0) : nil
        }
    }
    
}

// MARK: - select operations
extension ThreeWaysTrie {
    internal func _select(node: Node?, rank: Int) -> (key: String, value: Value)? {
        guard
            let nodeChar = node?.char
        else { return nil }
        
        let leftCount = node?.left?.count ?? 0
        if leftCount > rank {
            
            return _select(node: node?.left, rank: rank)
        }
        let r = node?.value != nil ? 1 : 0
        let midCount = node?.mid?.count ?? 0
        if rank >= leftCount + midCount + r {
            let localRank = rank - leftCount - midCount - r
            
            return _select(node: node?.right, rank: localRank)
        } else {
            let prefix = String(nodeChar)
            let localRank = rank - leftCount - r
            if let midResult: (key: String, value: Value) = _select(node: node?.mid, rank: localRank) {
                
                return (prefix + midResult.key, midResult.value)
            } else {
                
                // If this is a leaf node then it must have its value set!
                return (prefix, node!.value!)
            }
        }
    }
    
    internal func _selectNode(node: Node?, rank: Index) -> Node? {
        guard
            node != nil
        else { return nil }
        
        let leftCount = node!.left?.count ?? 0
        if leftCount > rank {
            
            return _selectNode(node: node!.left, rank: rank)
        }
        let r = node!.value != nil ? 1 : 0
        let midCount = node!.mid?.count ?? 0
        if rank >= leftCount + midCount + r {
            let localRank = rank - leftCount - midCount - r
            
            return _selectNode(node: node!.right, rank: localRank)
        } else {
            let localRank = rank - leftCount - r
            
            return _selectNode(node: node!.mid, rank: localRank) ?? node
        }
    }
    
}

// MARK: - forEach operations
extension ThreeWaysTrie {
    internal func _forEach(node: Node?, prefix: String = "", body: ((key: String, value: Value)) throws -> Void) rethrows {
        guard
            let nodeChar = node?.char
        else { return }
        
        try _forEach(node: node?.left, prefix: prefix, body: body)
        
        let nextPrefix = prefix + String(nodeChar)
        if let v = node?.value {
            try body((nextPrefix, v))
        }
        try _forEach(node: node?.mid, prefix: nextPrefix, body: body)
        
        try _forEach(node: node?.right, prefix: prefix, body: body)
    }
    
    internal func _forEach(node: Node?, prefix: String = "", matching pattern: String, at patternIndex: String.Index, body: ((key: String, value: Value)) throws -> Void) rethrows {
        guard
            let nodeChar = node?.char
        else { return }
        
        let patternChar = pattern[patternIndex]
        
        if patternChar == "." || patternChar < nodeChar {
            try _forEach(node: node?.left, prefix: prefix, matching: pattern, at: patternIndex, body: body)
        }
        
        if patternChar == "." || patternChar == nodeChar {
            let indexOfLastPatternChar = pattern.index(before: pattern.endIndex)
            let nextPrefix = prefix + String(nodeChar)
            if
                patternIndex == indexOfLastPatternChar,
                let v = node?.value
            {
                try body((nextPrefix, v))
            }
            if patternIndex < indexOfLastPatternChar {
                try _forEach(node: node?.mid, prefix: nextPrefix, matching: pattern, at: pattern.index(after: patternIndex), body: body)
            }
        }
        
        if patternChar == "." || patternChar > nodeChar {
            try _forEach(node: node?.right, prefix: prefix, matching: pattern, at: patternIndex, body: body)
        }
    }
    
}

// MARK: - filter
extension ThreeWaysTrie {
    func _filter(node: Node?, prefix: String = "", by isIncluded: ((key: String, value: Value)) throws -> Bool) rethrows -> Node? {
        guard
            let nodeChar = node?.char
        else { return nil }
        
        node?.left = try _filter(node: node?.left, prefix: prefix, by: isIncluded)
        
        let nextPrefix = prefix + String(nodeChar)
        if
            let v = node?.value,
            try isIncluded((nextPrefix, v)) == false
        {
            node?.value = nil
        }
        node?.mid = try _filter(node: node?.mid, prefix: nextPrefix, by: isIncluded)
        
        node?.right = try _filter(node: node?.right, prefix: prefix, by: isIncluded)
        
        node?._updateCount()
        
        return node?._isEmpty == false ? node : nil
    }
    
}

// MARK: - mapValues
extension ThreeWaysTrie {
    internal func _mapValues<T>(node: Node?, transform: (Value) throws -> T) rethrows -> ThreeWaysTrie<T>.Node? {
        guard
            node != nil
        else { return nil }
        
        let mapped = ThreeWaysTrie<T>.Node(char: node!.char)
        mapped.count = node!.count
        
        mapped.left = try _mapValues(node: node!.left, transform: transform)
        
        if let v = node!.value {
            let mV = try transform(v)
            mapped.value = mV
        }
        mapped.mid = try _mapValues(node: node!.mid, transform: transform)
        
        mapped.right = try _mapValues(node: node!.right, transform: transform)
        
        return mapped
    }
    
}

// MARK: - compactMapValues
extension ThreeWaysTrie {
    internal func _compactMapValues<T>(node: Node?, transform: (Value) throws -> T?) rethrows -> ThreeWaysTrie<T>.Node? {
        guard
            node != nil
        else { return nil }
        
        let mapped = ThreeWaysTrie<T>.Node(char: node!.char)
        
        mapped.left = try _compactMapValues(node: node!.left, transform: transform)
        if let v = node!.value {
            mapped.value = try transform(v)
        }
        mapped.mid = try _compactMapValues(node: node!.mid, transform: transform)
        
        mapped.right = try _compactMapValues(node: node!.right, transform: transform)
        
        mapped._updateCount()
        
        return mapped._isEmpty ? nil : mapped
    }
    
}

// MARK: - traverse
extension ThreeWaysTrie {
    internal enum _Traversal: CaseIterable {
        case inOrder
        case reverseInOrder
        case preOrder
    }
    
    internal func _traverse(traversal: _Traversal, _ body: (inout Bool, String, ThreeWaysTrie.Node) throws -> Void) rethrows {
        switch traversal {
        case .inOrder:
            try root?._inOrderVisit(body)
        case .reverseInOrder:
            try root?._reverseInOrderVisit(body)
        case .preOrder:
            try root?._preOrderVisit(body)
        }
    }
    
}
