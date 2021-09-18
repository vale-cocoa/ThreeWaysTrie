//
//  ThreeWaysTrieCollectionTests.swift
//  ThreeWaysTrieTests
//
//  Created by Valeriano Della Longa on 2021/09/18.
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

final class ThreeWaysTrieCollectionTests: BaseTrieTestClass {
    typealias SutElement = ThreeWaysTrie<Int>.Element
    func testCount() {
        for (value, key) in givenKeys().enumerated() {
            sut.root = sut._put(node: sut.root, key: key, value: value, index: key.startIndex, uniquingKeysWith: { $1 })
            XCTAssertEqual(sut.count, sut.root?.count)
        }
        for key in givenKeys() {
            sut.root = sut._remove(node: sut.root, key: key, index: key.startIndex).nodeAfterRemoval
            XCTAssertEqual(sut.count, (sut.root?.count ?? 0))
        }
    }
    
    func testIsEmpty() {
        sut = ThreeWaysTrie()
        XCTAssertTrue(sut.isEmpty)
        
        whenIsNotEmpty()
        XCTAssertFalse(sut.isEmpty)
    }
    
    func testStartIndex() {
        for (value, key) in givenKeys().enumerated() {
            sut.root = sut._put(node: sut.root, key: key, value: value, index: key.startIndex, uniquingKeysWith: { $1 })
            XCTAssertEqual(sut.startIndex, 0)
        }
        for key in givenKeys() {
            sut.root = sut._remove(node: sut.root, key: key, index: key.startIndex).nodeAfterRemoval
            XCTAssertEqual(sut.startIndex,  0)
        }
    }
    
    func testEndIndex() {
        for (value, key) in givenKeys().enumerated() {
            sut.root = sut._put(node: sut.root, key: key, value: value, index: key.startIndex, uniquingKeysWith: { $1 })
            XCTAssertEqual(sut.endIndex, sut.count)
        }
        for key in givenKeys() {
            sut.root = sut._remove(node: sut.root, key: key, index: key.startIndex).nodeAfterRemoval
            XCTAssertEqual(sut.endIndex,  sut.count)
        }
    }
    
    func testFirst() {
        sut = ThreeWaysTrie()
        XCTAssertNil(sut.first)
        
        for (value, key) in givenKeys().enumerated() {
            sut.root = sut._put(node: sut.root, key: key, value: value, index: key.startIndex, uniquingKeysWith: { $1 })
            let expectedResult = sut!.map({ $0 }).first!
            let result = sut.first
            XCTAssertEqual(result?.key, expectedResult.key)
            XCTAssertEqual(result?.value, expectedResult.value)
        }
    }
    
    func testLast() {
        sut = ThreeWaysTrie()
        XCTAssertNil(sut.last)
        
        for (value, key) in givenKeys().enumerated() {
            sut.root = sut._put(node: sut.root, key: key, value: value, index: key.startIndex, uniquingKeysWith: { $1 })
            let expectedResult = sut!.map({ $0 }).last!
            let result = sut.last
            XCTAssertEqual(result?.key, expectedResult.key)
            XCTAssertEqual(result?.value, expectedResult.value)
        }
    }
    
    func testIndexAfter() {
        var idx = 0
        for offset in 0..<10 {
            idx = sut.index(after: idx)
            XCTAssertEqual(idx, offset + 1)
        }
    }
    
    func testFormIndexAfter() {
        var idx = 0
        for _ in 0..<10 {
            let prev = idx
            sut.formIndex(after: &idx)
            XCTAssertEqual(idx, prev + 1)
        }
    }
    
    func testIndexBefore() {
        var idx = 10
        for _ in 0..<10 {
            let prev = idx
            idx = sut.index(before: idx)
            XCTAssertEqual(idx, prev - 1)
        }
    }
    
    func testFormIndexBefore() {
        var idx = 10
        for _ in 0..<10 {
            let prev = idx
            sut.formIndex(before: &idx)
            XCTAssertEqual(idx, prev - 1)
        }
    }
    
    func testSubscript() {
        whenIsNotEmpty()
        let sortedElements = sut!.map({ $0 })
        for idx in sut.startIndex..<sut.endIndex {
            let result = sut[idx]
            let expectedResult = sortedElements[idx]
            XCTAssertEqual(result.key, expectedResult.key)
            XCTAssertEqual(result.value, expectedResult.value)
        }
    }
    
    // MARK: - firstIndex(where:) tests
    func testFirstIndex_whenIsEmpty_thenPredicateNeverExecutesAndReturnsNil() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        var countOfExecutions = 0
        let predicate: (SutElement) -> Bool = { _ in
            countOfExecutions += 1
            
            return false
        }
        
        XCTAssertNil(sut.firstIndex(where: predicate))
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testFirstIndex_whenIsNotEmptyAndPredicateReturnsFalseOnEveryTrieElement_thenPredicateExecutesInRankOrderOnEveryTrieElementAndReturnsNil() {
        whenIsNotEmpty()
        var capturedElements: Array<SutElement> = []
        let predicate: (SutElement) -> Bool = {
            capturedElements.append($0)
            
            return false
        }
        let sortedElements = sut!.map({ $0 })
        
        XCTAssertNil(sut.firstIndex(where: predicate))
        XCTAssertTrue(capturedElements.elementsEqual(sortedElements, by: { $0.key == $1.key && $0.value == $1.value }))
    }
    
    func testFirstIndex_whenIsNotEmptyAndPredicateReturnsTrueForSomeElementsInTrie_thenReturnsIndexOfFirstElementTestingPositive() {
        whenIsNotEmpty()
        var countOfExectutions = 0
        let predicate: (SutElement) -> Bool = {
            countOfExectutions += 1
            
            return $0.value % 2 == 1
        }
        let expectedResult = sut!.map({ $0 }).firstIndex(where: predicate)!
        countOfExectutions = 0
        
        let result = sut.firstIndex(where: predicate)
        XCTAssertEqual(result, expectedResult)
        // might not have to test every element in trie:
        XCTAssertLessThanOrEqual(countOfExectutions, sut.count)
    }
    
    func testFirstIndex_whenPredicateThrows_thenRethrows() {
        whenIsNotEmpty()
        do {
            let _ = try sut.firstIndex(where: { _ in throw someError })
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - lastIndex(where:) tests
    func testLastIndex_whenIsEmpty_thenPredicateNeverExecutesAndReturnsNil() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        var countOfExecutions = 0
        let predicate: (SutElement) -> Bool = { _ in
            countOfExecutions += 1
            
            return false
        }
        
        XCTAssertNil(sut.lastIndex(where: predicate))
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testLastIndex_whenIsNotEmptyAndPredicateReturnsFalseOnEveryTrieElement_thenPredicateExecutesInReversedRankOrderOnEveryTrieElementAndReturnsNil() {
        whenIsNotEmpty()
        var capturedElements: Array<SutElement> = []
        let predicate: (SutElement) -> Bool = {
            capturedElements.append($0)
            
            return false
        }
        let reversedSortedElements = sut!.map({ $0 }).reversed()
        
        XCTAssertNil(sut.lastIndex(where: predicate))
        XCTAssertTrue(capturedElements.elementsEqual(reversedSortedElements, by: { $0.key == $1.key && $0.value == $1.value }))
    }
    
    func testLastIndex_whenIsNotEmptyAndPredicateReturnsTrueForSomeElementsInTrie_thenReturnsIndexOfLastElementTestingPositive() {
        whenIsNotEmpty()
        var countOfExectutions = 0
        let predicate: (SutElement) -> Bool = {
            countOfExectutions += 1
            
            return $0.value % 2 == 1
        }
        let expectedResult = sut!.map({ $0 }).lastIndex(where: predicate)!
        countOfExectutions = 0
        
        let result = sut.lastIndex(where: predicate)
        XCTAssertEqual(result, expectedResult)
        // might not have to test every element in trie:
        XCTAssertLessThanOrEqual(countOfExectutions, sut.count)
    }
    
    func testLastIndex_whenPredicateThrows_thenRethrows() {
        whenIsNotEmpty()
        do {
            let _ = try sut.lastIndex(where: { _ in throw someError })
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
}
