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

// MARK: - Equatable conformance
extension ThreeWaysTrie.Node: Equatable where Value: Equatable {
    static func == (lhs: ThreeWaysTrie<Value>.Node, rhs: ThreeWaysTrie<Value>.Node) -> Bool {
        guard lhs !== rhs else { return true }
        
        guard
            lhs.char == rhs.char,
            lhs.value == rhs.value,
            lhs.count == rhs.count
        else { return false }
        
        switch (lhs.left, rhs.left) {
        case (nil, nil): break
        case (.some(let lL), .some(let rL)) where lL == rL: break
        default: return false
        }
        
        switch (lhs.mid, rhs.mid) {
        case (nil, nil): break
        case (.some(let lM), .some(let rM)) where lM == rM: break
        default: return false
        }
        switch (lhs.right, rhs.right) {
        case (nil, nil): return true
        case (.some(let lR), .some(let rR)) where lR == rR: return true
        default: return false
        }
    }
    
}

// MARK: - Hashable
extension ThreeWaysTrie.Node: Hashable where Value: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(char)
        hasher.combine(value)
        hasher.combine(count)
        hasher.combine(left)
        hasher.combine(mid)
        hasher.combine(right)
    }
    
}

// MARK: - Codable conformance
extension ThreeWaysTrie.Node: Codable where Value: Codable {
    internal enum Error: Swift.Error {
        case emptyCharacter
    }
    
    private enum CodingKeys: String, CodingKey {
        case char
        case value
        case count
        case left
        case mid
        case right
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(String(char), forKey: .char)
        try container.encodeIfPresent(value, forKey: .value)
        try container.encode(count, forKey: .count)
        try container.encodeIfPresent(left, forKey: .left)
        try container.encode(mid, forKey: .mid)
        try container.encode(right, forKey: .right)
    }
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let charString = try container.decode(String.self, forKey: .char)
        guard
            let c = charString.first
        else { throw Error.emptyCharacter }
        
        self.init(char: c)
        
        self.value = try container.decodeIfPresent(Value.self, forKey: .value)
        self.count = try container.decode(Int.self, forKey: .count)
        
        self.left = try container.decodeIfPresent(Self.self, forKey: .left)
        self.mid = try container.decodeIfPresent(Self.self, forKey: .mid)
        self.right = try container.decodeIfPresent(Self.self, forKey: .right)
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
        
        // mid is supposed not be nil at this point otherwise this is
        // a termination node without a value set which is not allowed
        return mid!._floor(key: key + String(mid!.char), index: key.index(after: index), prefix: nextPrefix)
    }
    
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
        
        // mid is supposed not be nil at this point otherwise this is
        // a termination node without a value set which is not allowed
        return mid!._ceiling(key: key + String(mid!.char), index: key.index(after: index), prefix: nextPrefix)
    }
    
}
