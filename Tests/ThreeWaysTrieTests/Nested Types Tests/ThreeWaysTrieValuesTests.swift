//
//  ThreeWaysTrieValuesTests.swift
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

final class ThreeWaysTrieValuesTests: BaseTrieTestClass {
    func testValues_whenIsEmpty_thenIsEmpty() throws {
        try XCTSkipIf(!sut.isEmpty, "Trie must be empty for this test")
        XCTAssertTrue(sut.values.isEmpty)
    }
    
    func testValues_whenIsNotEmpty_thenContainsAllValuesInTrie() {
        whenIsNotEmpty()
        let expectedValues = sut!.map({ $0.value })
        XCTAssertTrue(sut.values.elementsEqual(expectedValues))
    }
    
    func testValuesSubscriptGet() {
        whenIsNotEmpty()
        for idx in sut.indices {
            XCTAssertEqual(sut[idx].value, sut.values[idx])
        }
    }
    
    func testValuesSubsciptModify() {
        whenIsNotEmpty()
        let expectedResult = sut!.map({ $0.value + 10 })
        for idx in sut.indices {
            sut.values[idx] += 10
        }
        XCTAssertTrue(sut.values.elementsEqual(expectedResult))
    }
    
    func testValues_COW() {
        whenIsNotEmpty()
        var prevValues = sut.values
        for idx in prevValues.indices {
            prevValues[idx] += 10
        }
        XCTAssertFalse(sut.values.elementsEqual(prevValues))
        
        let clone = sut!
        for idx in sut.indices {
            sut.values[idx] += 10
        }
        XCTAssertFalse(sut.root === clone.root)
        XCTAssertFalse(sut.values.elementsEqual(clone.values))
    }
    
    func testValues_EquatableConformance() {
        whenIsNotEmpty()
        var lhs = sut!
        let rhs = lhs
        XCTAssertEqual(lhs.values, rhs.values)
        
        let idx = lhs.indices.randomElement()!
        let removedElement = lhs.remove(at: idx)
        XCTAssertNotEqual(lhs.values, rhs.values)
        
        lhs[removedElement.key] = removedElement.value
        XCTAssertFalse(lhs.root === rhs.root)
        XCTAssertEqual(lhs.values, rhs.values)
    }
    
}
