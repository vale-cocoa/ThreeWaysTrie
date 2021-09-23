//
//  ThreeWaysTrie+Keys.swift
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
    /// A view of a trie's keys.
    public struct Keys: BidirectionalCollection, RandomAccessCollection, Equatable {
        fileprivate let _trie: ThreeWaysTrie
        
        fileprivate init(_ trie: ThreeWaysTrie) {
            self._trie = trie
        }
        
        public typealias Element = Key
        
        public typealias Index = ThreeWaysTrie.Index
        
        @inline(__always)
        public var startIndex: Index { _trie.startIndex }
        
        @inline(__always)
        public var endIndex: Index { _trie.endIndex }
        
        @inline(__always)
        public func index(after i: Index) -> Index {
            _trie.index(after: i)
        }
        
        @inline(__always)
        public func formIndex(after i: inout ThreeWaysTrie.Index) {
            _trie.formIndex(after: &i)
        }
        
        @inline(__always)
        public func index(before i: Index) -> Index {
            _trie.index(before: i)
        }
        
        @inline(__always)
        public func formIndex(before i: inout ThreeWaysTrie.Index) {
            _trie.formIndex(before: &i)
        }
        
        @inline(__always)
        public subscript(position: Index) -> Key {
            _trie[position].key
        }
        
        // Equatable conformance
        public static func == (lhs: Keys, rhs: Keys) -> Bool {
            guard lhs._trie.root !== rhs._trie.root else { return true }
            
            return lhs._trie.elementsEqual(rhs._trie, by: { $0.key == $1.key })
        }
        
    }
    
    /// A collection containing just the keys of the trie.
    ///
    /// When iterated over, keys appear in this collection in the same order as
    /// they occur in the trie's key-value pairs. Each key in the keys
    /// collection has a unique value.
    ///
    ///     let countryCodes: ThreeWaysTrie<String> = [
    ///         "BR": "Brazil",
    ///         "GH": "Ghana",
    ///         "JP": "Japan"
    ///     ]
    ///     print(countryCodes)
    ///     // Prints "["BR": "Brazil", "GH": "Ghana", "JP": "Japan",]"
    ///
    ///     for k in countryCodes.keys {
    ///         print(k)
    ///     }
    ///     // Prints "BR"
    ///     // Prints "GH"
    ///     // Prints "JP"
    @inline(__always)
    public var keys: Keys { Keys(self) }
    
}
