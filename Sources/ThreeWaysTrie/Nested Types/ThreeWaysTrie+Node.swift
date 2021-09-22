//
//  ThreeWaysTrie+Node.swift
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

extension ThreeWaysTrie {
    internal final class Node: NSCopying {
        internal let char: Character
        internal var value: Value? = nil
        internal var count: Int = 0
        
        internal var left: Node? = nil
        internal var mid: Node? = nil
        internal var right: Node? = nil
        
        internal init(char: Character) {
            self.char = char
        }
        
        @usableFromInline
        internal var _isEmpty: Bool {
            value == nil && left == nil && mid == nil && right == nil
        }
        
        internal func copy(with zone: NSZone? = nil) -> Any {
            let clone = Node(char: char)
            if let v = value as? NSCopying {
                clone.value = (v.copy(with: zone) as! Value)
            } else {
                clone.value = value
            }
            clone.count = count
            if left != nil {
                clone.left = left!.copy(with: zone) as! Self
            }
            if mid != nil {
                clone.mid = mid!.copy(with: zone) as! Self
            }
            if right != nil {
                clone.right = right!.copy(with: zone) as! Self
            }
            
            return clone
        }
        
        @usableFromInline
        internal func _clone() -> Self {
            copy() as! Self
        }
        
        @usableFromInline
        func _updateCount() {
            count = value != nil ? 1 : 0
            count += left?.count ?? 0
            count += mid?.count ?? 0
            count += right?.count ?? 0
        }
        
    }
    
}

// MARK: - Traversals
extension ThreeWaysTrie.Node {
    @discardableResult
    internal func _inOrderVisit(prefix: String = "", _ body: (inout Bool, String, ThreeWaysTrie.Node) throws -> Void) rethrows -> Bool {
        var stop = false
        stop = try left?._inOrderVisit(prefix: prefix, body) ?? false
        
        guard
            stop == false
        else { return stop }
        
        let nextPrefix = prefix + String(char)
        try body(&stop, nextPrefix, self)
        if stop == false {
            stop = try mid?._inOrderVisit(prefix: nextPrefix, body) ?? false
        }
        if stop == false {
            stop = try right?._inOrderVisit(prefix: prefix, body) ?? false
        }
        
        return stop
    }
    
    @discardableResult
    internal func _reverseInOrderVisit(prefix: String = "", _ body: (inout Bool, String, ThreeWaysTrie.Node) throws -> Void) rethrows -> Bool {
        var stop = false
        stop = try right?._reverseInOrderVisit(prefix: prefix, body) ?? false
        
        guard
            stop == false
        else { return stop }
        
        let nextPrefix = prefix + String(char)
        try body(&stop, nextPrefix, self)
        if stop == false {
            stop = try mid?._reverseInOrderVisit(prefix: nextPrefix, body) ?? false
        }
        
        if stop == false {
            stop = try left?._reverseInOrderVisit(prefix: prefix, body) ?? false
        }
        
        return stop
    }
    
    @discardableResult
    internal func _preOrderVisit(prefix: String = "", _ body: (inout Bool, String, ThreeWaysTrie.Node) throws -> Void) rethrows -> Bool {
        var stop = false
        let nextPrefix = prefix + String(char)
        try body(&stop, nextPrefix, self)
        guard
            stop == false
        else { return stop }
        
        stop = try mid?._preOrderVisit(prefix: nextPrefix, body) ?? false
        
        if stop == false {
            stop = try left?._preOrderVisit(prefix: prefix, body) ?? false
        }
        
        if stop == false {
            stop = try right?._preOrderVisit(prefix: prefix, body) ?? false
        }
        
        return stop
    }
    
}

// MARK: - floor and ceiling operations
extension ThreeWaysTrie.Node {
    /*
    internal func _floor(key: String, index: String.Index, prefix: String = "") -> String? {
        let c = key[index]
        if c < char {
            
            return left?._floor(key: key, index: index, prefix: prefix)
        }
        
        if
            c > char,
            let rResult = right?._floor(key: key, index: index, prefix: prefix)
        {
            
            return rResult
        }
        
        let nextPrefix = prefix + String(char)
        if
            index < key.index(before: key.endIndex),
            let midResult = mid?._floor(key: key, index: key.index(after: index), prefix: nextPrefix)
        {
            
            return midResult
        }
        if value != nil {
            
            return nextPrefix
        }
        
        // mid is supposed not to be nil at this point otherwise this is
        // a termination node without a value set which is not allowed
        return mid!._floor(key: key + String(mid!.char), index: key.index(after: index), prefix: nextPrefix)
    }
    */
    internal func _ceiling(key: String, index: String.Index, prefix: String = "") -> String? {
        let c = key[index]
        if c > char {
            
            return right?._ceiling(key: key, index: index, prefix: prefix)
        }
        if
            c < char,
            let lResult = left?._ceiling(key: key, index: index, prefix: prefix)
        {
            
            return lResult
        }
        
        let nextPrefix = prefix + String(char)
        if
            index < key.index(before: key.endIndex),
            let midResult = mid?._ceiling(key: key, index: key.index(after: index), prefix: nextPrefix)
        {
            
            return midResult
        }
        
        if value != nil {
            
            return nextPrefix
        }
        
        // mid is supposed not to be nil at this point otherwise this is
        // a termination node without a value set which is not allowed
        return mid!._ceiling(key: key + String(mid!.char), index: key.index(after: index), prefix: nextPrefix)
    }
    
    internal func _floor(key: String, index: String.Index, prefix: String = "") -> String? {
        let c = key[index]
        if c < char { return left?._floor(key: key, index: index, prefix: prefix) }
        
        if
            c > char,
            let rResult = right?._floor(key: key, index: index, prefix: prefix)
        { return rResult }
        
        let nextPrefix = prefix + String(char)
        if
            c == char,
            index < key.index(before: key.endIndex),
            let midResult = mid?._floor(key: key, index: key.index(after: index), prefix: nextPrefix)
        { return midResult }
        
        if value != nil {
            
            return nextPrefix
        }
        
        var floorKey: String? = nil
        if c > char {
            mid?._reverseInOrderVisit(prefix: nextPrefix, { stop, k, node in
                guard node.value != nil else { return }
                
                stop = true
                floorKey = k
            })
        } else {
            left?._reverseInOrderVisit(prefix: prefix, { stop, k, node in
                guard
                    node.value != nil
                else { return }
                
                stop = true
                floorKey = k
            })
        }
        
        return floorKey
    }
    
}
