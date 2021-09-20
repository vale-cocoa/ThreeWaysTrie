//
//  ThreeWaysTrieKeysTests.swift
//  ThreeWaysTrieTests
//
//  Created by Valeriano Della Longa on 2021/09/20.
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

import XCTest
@testable import ThreeWaysTrie

final class ThreeWaysTrieKeysTests: BaseTrieTestClass {
    func testKeys_whenTrieIsEmpty_thenIsEmpty() throws {
        try XCTSkipIf(!sut.isEmpty, "Trie must be empty for this test")
        XCTAssertTrue(sut.keys.isEmpty)
    }
    
    func testKeys_whenTrieIsNotEmpty_thenKeysContainsAllKeysFromTrie() {
        whenIsNotEmpty()
        let expectedResult = sut!.map({ $0.key })
        XCTAssertTrue(sut.keys.elementsEqual(expectedResult))
    }
    
    func testKeysSubscript() {
        whenIsNotEmpty()
        for idx in sut.startIndex..<sut.endIndex {
            XCTAssertEqual(sut[idx].key, sut.keys[idx])
        }
        
    }
    
    func testKeys_COW() {
        whenIsNotEmpty()
        let keys = sut.keys
        let idx = sut.indices.randomElement()!
        let prevKey = sut.remove(at: idx).key
        XCTAssertEqual(keys[idx], prevKey)
        XCTAssertNotEqual(sut[idx].key, keys[idx])
    }
    
    func testKeysEquatableConformance() {
        whenIsNotEmpty()
        var lhs = sut!
        let rhs = lhs
        XCTAssertEqual(lhs.keys, rhs.keys)
        
        let idx = lhs.indices.randomElement()!
        let removedElement = lhs.remove(at: idx)
        XCTAssertNotEqual(lhs.keys, rhs.keys)
        
        lhs[removedElement.key] = removedElement.value
        XCTAssertFalse(lhs.root === rhs.root)
        XCTAssertEqual(lhs.keys, rhs.keys)
    }
    
}
