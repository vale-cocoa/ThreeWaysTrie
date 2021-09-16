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
    @inline(__always)
    public var count: Int { root?.count ?? 0 }
        
    @inline(__always)
    public var isEmpty: Bool { root == nil }
    
    @inlinable
    public var startIndex: Int { 0 }
    
    @inline(__always)
    public var endIndex: Int { root?.count ?? 0 }
    
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
    
    public subscript(position: Int) -> Element {
        precondition(0..<endIndex ~= position, "Index out of bounds")
        
        return _select(node: root, rank: position)!
    }
    
    public func firstIndex(where predicate: (Element) throws -> Bool) rethrows -> Index? {
        var idx = -1
        try _traverse(traversal: .inOrder, { stop, key, node in
            guard
                let v = node.value
            else { return }
            
            idx += 1
            stop = try predicate((key, v))
        })
        
        return startIndex..<endIndex ~= idx ? idx : nil
    }
    
    public func lastIndex(where predicate: (Element) throws -> Bool) rethrows -> Index? {
        var idx = count
        try _traverse(traversal: .reverseInOrder, { stop, key, node in
            guard
                let v = node.value
            else { return }
            
            idx -= 1
            stop = try predicate((key, v))
        })
        
        return startIndex..<endIndex ~= idx ? idx : nil
    }
    
}
