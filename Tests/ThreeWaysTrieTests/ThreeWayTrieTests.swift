//
//  ThreeWaysTrieTests.swift
//  ThreeWaysTrieTests
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

import XCTest
@testable import ThreeWaysTrie

final class ThreeWaysTrieTests: BaseTrieTestClass {
    // MARK: - init tests
    func testInit() {
        sut = ThreeWaysTrie()
        
        XCTAssertNotNil(sut)
        XCTAssertNil(sut.root)
    }
    
    // MARK: - _makeUnique() tests
    func testMakeUnique_whenRootIsNil_thenRootStaysNil() throws {
        try XCTSkipIf(sut.root != nil, "Root must be nil for this test")
        
        sut._makeUnique()
        XCTAssertNil(sut.root)
    }
    
    func testMakeUnique_whenRootIsNotNilAndIsUniquelyReferenced_thenRootStaysTheSameInstance() {
        whenRootIsNotNil()
        weak var prevRoot = sut.root
        
        sut._makeUnique()
        XCTAssertTrue(sut.root === prevRoot)
        
    }
    
    func testMakeUnique_whenRootIsNotNilAndNotUniquelyReferenced_thenRootIsCloned() {
        whenRootIsNotNil()
        let cp = sut!
        
        sut._makeUnique()
        assertAreEqualNodesButNotSameInstance(lhs: sut.root, rhs: cp.root)
    }
    
    // MARK: - keys(with:) tests
    func testKeysWith_whenIsEmpty_thenReturnsEmptyArray() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        
        let result = sut.keys(with: "")
        XCTAssertTrue(result.isEmpty)
    }
    
    func testKeysWith_whenIsNotEmptyAndPrefixIsEmpty_thenReturnsAllTrieKeys() {
        whenIsNotEmpty()
        var allKeys: Array<String> = []
        sut._forEach(node: sut.root, body: { allKeys.append($0.key) })
        
        let result = sut.keys(with: "")
        XCTAssertEqual(result, allKeys)
    }
    
    func testKeysWith_whenIsNotEmptyAndPrefixIsNotEmpty_thenReturnsKeysWithSpecifiedPrefix() {
        whenIsNotEmpty()
        let prefix = "sh"
        var expectedResult: Array<String> = []
        sut._forEach(node: sut.root, body: {
            guard $0.key.hasPrefix(prefix) else { return }
            expectedResult.append($0.key)
        })
        
        let result = sut.keys(with: prefix)
        XCTAssertEqual(result, expectedResult)
    }
    
    func testKeysWith_whenIsNotEmptyAndPrefixMatchesKey_thenResultAlsoContainsSuchKey() {
        whenIsNotEmpty()
        let prefix = "she"
        var expectedResult: Array<String> = []
        sut._forEach(node: sut.root, body: {
            guard $0.key.hasPrefix(prefix) else { return }
            expectedResult.append($0.key)
        })
        
        let result = sut.keys(with: prefix)
        XCTAssertEqual(result, expectedResult)
    }
    
    func testKeysWith_whenIsNotEmptyAndNoKeysInTrieHasSpecifiedPrefix_thenReturnsEmptyArray() {
        whenIsNotEmpty()
        let prefix = "qu"
        
        let result = sut.keys(with: prefix)
        XCTAssertTrue(result.isEmpty)
    }
    
    // MARK: - keys(matching:) tests
    func testKeysMatching_whenIsEmtpy_thenReturnsEmptyArray() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        
        let result = sut.keys(matching: "...")
        XCTAssertTrue(result.isEmpty)
    }
    
    func testKeysMatching_whenPatternIsEmpty_thenReturnsEmptyArray() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        
        var result = sut.keys(matching: "")
        XCTAssertTrue(result.isEmpty)
        
        whenIsNotEmpty()
        result = sut.keys(matching: "")
        XCTAssertTrue(result.isEmpty)
    }
    
    func testKeysMatching_whenIsNotEmptyAndPatternIsNotEmptyAndMatchesOneKey_thenReturnsArrayContainingSuchKey() {
        whenIsNotEmpty()
        let pattern = "she"
        var expectedResult: Array<String> = []
        sut.root?._preOrderVisit({ stop, key, node in
            guard
                node.value != nil
            else { return }
            
            if key == pattern {
                expectedResult.append(key)
                stop = true
            }
        })
        
        let result = sut.keys(matching: pattern)
        XCTAssertEqual(result, expectedResult)
    }
    
    func testKeysMatching_whenIsNotEmptyAndPatternContainsWildCardsAndMatchesSomeKeys_thenReturnsArrayWithSuchKeys() {
        whenIsNotEmpty()
        let pattern = "s........"
        var expectedResult: Array<String> = []
        sut._forEach(node: sut.root, body: {
            guard
                $0.key.count == pattern.count,
                $0.key.first == pattern.first
            else { return }
            
            expectedResult.append($0.key)
        })
        
        let result = sut.keys(matching: pattern)
        XCTAssertEqual(result, expectedResult)
    }
    
    func testKeysMatching_whenIsNotEmptyAndPatternIsNotEmptyAndNoKeyMatchesPattern_thenReturnsEmptyArray() {
        whenIsNotEmpty()
        let pattern = "she.."
        
        let result = sut.keys(matching: pattern)
        XCTAssertTrue(result.isEmpty)
    }
    
    // MARK: - rank(_:) tests
    func testRank_whenIsEmpty_thenReturnsZero() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        
        for key in givenKeys() {
            XCTAssertEqual(sut.rank(of: key), 0)
        }
    }
    
    func testRank_whenIsNotEmptyAndKeyIsInTrie_thenReturnsIndexOfKeyInAllTrieKeysSorted() {
        let keys = givenKeys()
        let sortedKeys = keys.sorted()
        whenIsNotEmpty()
        for (expectedRank, key) in sortedKeys.enumerated() {
            XCTAssertEqual(sut.rank(of: key), expectedRank)
        }
    }
    
    func testRank_whenIsNotEmptyAndKeyIsSmallerThanSmallestKeyInTrie_thenReturnsZero() {
        whenIsNotEmpty()
        let key = "at"
        XCTAssertEqual(sut.rank(of: key), 0)
    }
    
    func testRank_whenIsNotEmptyAndKeyIsLargerThanLargestKeyInTrie_thenReturnsValueEqualsToTrieCount() {
        whenIsNotEmpty()
        let key = "zoe"
        XCTAssertEqual(sut.rank(of: key), sut.count)
    }
    
    func testRank_whenIsnotEmptyAndKeyIsNotInTrie_thenReturnsIndexOfInsertionInTrieKeysSorted() {
        whenIsNotEmpty()
        let sortedKeys = givenKeys().sorted()
        let newKeys = sortedKeys.map({ $0 + "z" })
        for key in newKeys {
            let expectedResult = (sortedKeys as NSArray).index(of: key, inSortedRange: NSRange(0..<sortedKeys.count), options: .insertionIndex, usingComparator: {
                ($0 as! String).compare($1 as! String)
            })
            XCTAssertEqual(sut.rank(of: key), expectedResult)
        }
    }
    
    // MARK: - floor(_:) tests
    func testFloor_whenIsEmpty_thenReturnsNil() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        
        for key in givenKeys() {
            XCTAssertNil(sut.floor(key))
        }
    }
    
    func testFloor_whenIsNotEmptyAndKeyIsInTrie_thenReturnsKey() {
        whenIsNotEmpty()
        for key in givenKeys() {
            XCTAssertEqual(sut.floor(key), key)
        }
    }
    
    func testFloor_whenIsNotEmptyAndKeyIsSmallerThanSmallestKeyInTrie_thenReturnsNil() {
        whenIsNotEmpty()
        let key = "be"
        XCTAssertNil(sut.floor(key))
    }
    
    func testFloor_whenIsNotEmptyAndKeyIsLargerThanLargestKeyInTire_thenReturnsLargestKeyInTrie() {
        whenIsNotEmpty()
        let sortedKeys = givenKeys().sorted()
        let key = "to"
        XCTAssertEqual(sut.floor(key), sortedKeys.last)
    }
    
    func testFloor_whenIsNotEmptyAndKeyIsBetweenTwoKeysInTrie_thenReturnsTheSmallestOfTheTwoKeysInTrie() {
        whenIsNotEmpty()
        let sortedKeys = givenKeys().sorted()
        for expectedKey in sortedKeys.dropLast() {
            let key = expectedKey + "z"
            XCTAssertEqual(sut.floor(key), expectedKey)
        }
    }
    
    // MARK: - ceiling(_:) tests
    func testCeiling_whenISempty_thenReturnsNil() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        
        for key in givenKeys() {
            XCTAssertNil(sut.ceiling(key))
        }
    }
    
    func testCeiling_whenIsNotEmptyAndKeyIsInTrie_thenReturnsKey() {
        whenIsNotEmpty()
        for key in givenKeys() {
            XCTAssertEqual(sut.ceiling(key), key)
        }
    }
    
    func testCeiling_whenIsNotEmptyAndKeyIsLargerThanLargestKeyInTrie_thenReturnsNil() {
        whenIsNotEmpty()
        let key = "to"
        XCTAssertNil(sut.ceiling(key))
    }
    
    func testCeiling_whenIsNotEmptyAndKeyIsSmallerThanSmallestKeyInTrie_thenReturnsSmallestKeyInTrie() {
        whenIsNotEmpty()
        let sortedKeys = givenKeys().sorted()
        let key = "be"
        XCTAssertEqual(sut.ceiling(key), sortedKeys.first)
    }
    
    func testCeiling_whenIsNotEmptyAndKeyIsBetweenTwoKeysInTrie_thenReturnsTheLargerOfTheTwoKeysInTrie() {
        whenIsNotEmpty()
        let sortedKeys = givenKeys().sorted()
        for expectedKey in sortedKeys.dropFirst() {
            let key = String(expectedKey.dropLast())
            XCTAssertEqual(sut.ceiling(key), expectedKey)
        }
    }
    
    // MARK: - Equatable conformance tests
    func testEquatable() {
        // when both have nil root, then returns true:
        var lhs = ThreeWaysTrie<Int>()
        var rhs = lhs
        XCTAssertEqual(lhs, rhs)
        
        // when one has nil root and other has root instance, then returns false
        whenIsNotEmpty()
        lhs.root = sut.root
        XCTAssertNotEqual(lhs, rhs)
        
        // when both shares same root instance, then returns true
        rhs.root = lhs.root
        XCTAssertEqual(lhs, rhs)
        
        // when have different root instances but root instances are equal,
        // then returns true:
        rhs.root = sut.root?._clone()
        XCTAssertFalse(lhs.root === rhs.root)
        XCTAssertEqual(lhs, rhs)
        
        // when have different root instances and root instances are not equal,
        // then returns false
        let newKey = "cheap"
        rhs.root = rhs._put(node: rhs.root, key: newKey, value: 1000, index: newKey.startIndex, uniquingKeysWith: { _ , latest in latest })
        XCTAssertNotEqual(lhs, rhs)
    }
    
    // MARK: - Hashable conformance tests
    func testHashable() {
        // As usual we use a Swift Set for testing Hashable conformance:
        var set: Set<ThreeWaysTrie<Int>> = []
        
        // when root is nil, resolve to same hash:
        set.insert(sut)
        var other = ThreeWaysTrie<Int>()
        XCTAssertFalse(set.insert(other).inserted)
        
        // when root is not nil, resolve to a different hash than one with nil root:
        whenIsNotEmpty()
        XCTAssertTrue(set.insert(sut).inserted)
        
        // when root is same instance resolves to same hash
        set.removeAll()
        set.insert(sut)
        other.root = sut.root
        XCTAssertFalse(set.insert(other).inserted)
        
        // when root is different instance but equal to other root,
        // then resolves to same hash:
        other.root = sut.root?._clone()
        XCTAssertFalse(set.insert(other).inserted)
        
        // when root instance is not equal to other root instance,
        // then resolves to different hash:
        let newKey = "newkey"
        other.root = other._put(node: other.root, key: newKey, value: Int.random(in: 1...10), index: newKey.startIndex, uniquingKeysWith: { _, latest in latest })
        XCTAssertTrue(set.insert(other).inserted)
    }
    
}
