//
//  ThreeWaysTrie+Values.swift
//  ThreeWaysTrie
//
//  Created by Valeriano Della Longa on 2021/09/12.
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
    /// A view of a trie's values.
    public struct Values: BidirectionalCollection, RandomAccessCollection, MutableCollection {
        fileprivate var _trie: ThreeWaysTrie
        
        fileprivate init(_ trie: ThreeWaysTrie) {
            self._trie = trie
        }
        
        public typealias Element = Value
        
        public typealias Index = ThreeWaysTrie.Index
        
        @inline(__always)
        public var count: Int { _trie.count }
        
        @inline(__always)
        public var isEmpty: Bool { _trie.isEmpty }
        
        @inline(__always)
        public var startIndex: Index { _trie.startIndex }
        
        @inline(__always)
        public var endIndex: Index { _trie.endIndex }
        
        @inline(__always)
        public func index(after i: Index) -> Index {
            _trie.index(after: i)
        }
        
        @inline(__always)
        public func formIndex(after i: inout Index) {
            _trie.formIndex(after: &i)
        }
        
        @inline(__always)
        public func index(before i: Index) -> Index {
            _trie.index(before: i)
        }
        
        @inline(__always)
        public func formIndex(before i: inout Index) {
            _trie.formIndex(before: &i)
        }
        
        public subscript(position: Index) -> Value {
            get { _trie[position].value }
            
            _modify {
                precondition(startIndex..<endIndex ~= position, "Index out of bounds")
                _trie._makeUnique()
                yield &_trie._selectNode(node: _trie.root, rank: position)!.value!
            }
        }
        
    }
    
    /// A collection containing just the values of the trie.
    ///
    /// When iterated over, values appear in this collection in the same order as
    /// they occur in the trie's key-value pairs.
    ///
    ///     let countryCodes = ["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]
    ///     print(countryCodes)
    ///     // Prints "["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]"
    ///
    ///     for v in countryCodes.values {
    ///         print(v)
    ///     }
    ///     // Prints "Brazil"
    ///     // Prints "Ghana"
    ///     // Prints "Japan"
    @inline(__always)
    public var values: Values {
        get { Values(self) }
        
        _modify {
            var values = Values(self)
            swap(&values._trie, &self)
            defer {
                self = values._trie
            }
            yield &values
        }
    }
    
}

// MARK: - Equatable conformance
extension ThreeWaysTrie.Values: Equatable where Value: Equatable {
    public static func == (lhs: ThreeWaysTrie.Values, rhs: ThreeWaysTrie.Values) -> Bool {
        guard
            lhs._trie.root !== rhs._trie.root
        else { return true }
        
        return lhs._trie.elementsEqual(rhs._trie, by: { $0.value == $1.value })
    }
    
}
