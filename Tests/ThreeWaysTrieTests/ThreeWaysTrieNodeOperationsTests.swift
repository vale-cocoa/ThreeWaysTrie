//
//  ThreeWaysTrieNodeOperationsTests.swift
//  ThreeWaysTrieTests
//
//  Created by Valeriano Della Longa on 2021/09/08.
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

final class ThreeWaysTrieNodeOperationsTests: XCTestCase {
    typealias Node = ThreeWaysTrie<Int>.Node
    var sut: ThreeWaysTrie<Int>!
    
    override func setUp() {
        super.setUp()
        
        sut = ThreeWaysTrie()
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    // MARK: - When
    func whenContainsKeys(from keys: Array<String>) throws {
        // Leverages on _put(node:key:value:index:uniquingKeysWith:) method
        guard
            !keys.isEmpty
        else { throw XCTSkip("keys must not be empty for this test") }
        
        for (value, key) in keys.enumerated() {
            sut.root = sut._put(node: sut.root, key: key, value: value, index: key.startIndex, uniquingKeysWith: {_, latest in latest })
        }
    }
    
    func whenContainsKeysFrom_SheSells_Sentence() {
        // sentence is "she sells", thus keys = ["she", "sells"]
        let root = Node(char: "s".first!)
        root.count = 2
        root.mid = Node(char: "h".first!)
        root.mid?.count = 2
        
        root.mid!.mid = Node(char: "e".first!)
        root.mid?.mid?.value = 0
        root.mid?.mid?.count = 1
        
        root.mid?.left = Node(char: "e".first!)
        root.mid?.left?.count = 1
        root.mid?.left?.mid = Node(char: "l".first!)
        root.mid?.left?.mid?.count = 1
        root.mid?.left?.mid?.mid = Node(char: "l".first!)
        root.mid?.left?.mid?.mid?.count = 1
        root.mid?.left?.mid?.mid?.mid = Node(char: "s".first!)
        root.mid?.left?.mid?.mid?.mid?.value = 1
        root.mid?.left?.mid?.mid?.mid?.count = 1
        sut.root = root
    }
    
    // MARK: - Tests
    // MARK: - _get(node:key:index:) tests
    func testGet_whenNodeIsNil_returnsNil() throws {
        try XCTSkipIf(sut.root != nil, "node must be nil for this test")
        
        let key = givenKeys().randomElement()!
        XCTAssertNil(sut._get(node: sut.root, key: key, index: key.startIndex))
    }
    
    func testGet_whenNodeIsNotNilAndKeyIsNotInTrieRootedAtNode_thenReturnsNil() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let keyNotInTrie = givenKeys().randomElement()! + ";"
       
        XCTAssertNil(sut._get(node: sut.root, key: keyNotInTrie, index: keyNotInTrie.startIndex))
    }
    
    func testGet_whenNodeIsNotNilAndKeyIsInTrieRootedAtNode_thenReturnsNodeInTrieForLastCharacterOfKey() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        for key in keys {
            let n = sut._get(node: sut.root, key: key, index: key.startIndex)
            XCTAssertNotNil(n)
            XCTAssertEqual(n?.char, key.last)
        }
    }
    
    // MARK: - _get(node:key:index:defaultValue:) test
    func testGetDefaultValue_whenNodeIsNil_thenReturnsNewRootAndNodeForLastCharacterOfKeyWithDefaultValueSet() throws {
        try XCTSkipIf(sut.root != nil, "node must be nil for this test")
        let key = givenKeys().randomElement()!
        var countOfExecutions = 0
        let v = Int.random(in: 1...100)
        let defaultValue: () -> Int = {
            countOfExecutions += 1
            
            return v
        }
        let (newRoot, finalNode) = sut._get(node: sut.root, key: key, index: key.startIndex, defaultValue: defaultValue)
        sut.root = newRoot
        let expectedNode = sut._get(node: sut.root, key: key, index: key.startIndex)
        XCTAssertEqual(countOfExecutions, 1)
        XCTAssertTrue(finalNode === expectedNode)
        XCTAssertEqual(sut.root?.count, 1)
        XCTAssertEqual(sut.root?.char, key.first)
        XCTAssertEqual(finalNode.char, key.last)
        XCTAssertEqual(finalNode.value, v)
        assertCountValuesAreValid(root: sut.root)
    }
    
    func testGetDefaulValue_whenNodeIsNotNilAndTrieRootedAtNodeContainsKeyAsPrefix_thenReturnsNewRootAndNodeForLastCharacterOfKeyWithDefaultValueSet() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let key = "sea"
        var countOfExecutions = 0
        let v = Int.random(in: 1...100)
        let defaultValue: () -> Int = {
            countOfExecutions += 1
            
            return v
        }
        let prevCount = sut.root!.count
        let (newRoot, finalNode) = sut._get(node: sut.root, key: key, index: key.startIndex, defaultValue: defaultValue)
        sut.root = newRoot
        let expectedNode = sut._get(node: sut.root, key: key, index: key.startIndex)
        XCTAssertEqual(countOfExecutions, 1)
        XCTAssertTrue(finalNode === expectedNode)
        XCTAssertEqual(sut.root?.count, prevCount + 1)
        XCTAssertEqual(finalNode.char, key.last)
        XCTAssertEqual(finalNode.value, v)
        assertCountValuesAreValid(root: sut.root)
    }
    
    func testGetDefaultValue_whenRootIsNotNilAndTrieRootedAtNodeContainsKey_thenReturnsNewRootAndFinalNodeForKeyWithOldValue() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let key = givenKeys().randomElement()!
        var countOfExecutions = 0
        let v = Int.random(in: 1...100)
        let defaultValue: () -> Int = {
            countOfExecutions += 1
            
            return v
        }
        let prevCount = sut.root!.count
        let (newRoot, finalNode) = sut._get(node: sut.root, key: key, index: key.startIndex, defaultValue: defaultValue)
        sut.root = newRoot
        let expectedNode = sut._get(node: sut.root, key: key, index: key.startIndex)
        XCTAssertEqual(countOfExecutions, 0)
        XCTAssertTrue(finalNode === expectedNode)
        XCTAssertEqual(sut.root?.count, prevCount)
        XCTAssertEqual(finalNode.char, key.last)
        XCTAssertEqual(finalNode.value, expectedNode?.value)
        assertCountValuesAreValid(root: sut.root)
    }
    
    // MARK: - _put(node:key:value:index:uniquingKeysWith:) tests
    func testPut_whenNodeIsNil_thenCreatesTrieRootedAtReturnedNodeContainingKeyAndValue() throws {
        try XCTSkipIf(sut.root != nil, "node must be nil for this test")
        let key = givenKeys().randomElement()!
        let value = Int.random(in: 0..<100)
        
        sut.root = sut._put(node: sut.root, key: key, value: value, index: key.startIndex, uniquingKeysWith: { _, _ in fatalError() })
        XCTAssertNotNil(sut.root)
        
        let n = sut._get(node: sut.root, key: key, index: key.startIndex)
        XCTAssertNotNil(n)
        XCTAssertEqual(n?.char, key.last)
        XCTAssertEqual(n?.value, value)
        XCTAssertEqual(sut.root?.count, 1)
    }
    
    func testPut_whenNodeIsNotNilAndKeyIsNotInTrieRootedAtNode_thenAddsKeyAndValueToTrieRootedAtNodeAndUpdatesNodeCountAndCombineDoesNotExecute() {
        var countOfExecutions = 0
        let combine: (Int, Int) -> Int = { _, latest in
            countOfExecutions += 1
            
            return latest
        }
        whenContainsKeysFrom_SheSells_Sentence()
        let newKey = "shells"
        let value = Int.random(in: 0..<100)
        let prevCount = sut.root!.count
        
        sut.root = sut._put(node: sut.root, key: newKey, value: value, index: newKey.startIndex, uniquingKeysWith: combine)
        let n = sut._get(node: sut.root, key: newKey, index: newKey.startIndex)
        XCTAssertNotNil(n)
        XCTAssertEqual(n?.char, newKey.last)
        XCTAssertEqual(n?.value, value)
        XCTAssertEqual(sut.root!.count, prevCount + 1)
        XCTAssertEqual(countOfExecutions, 0)
        
        // Let's also check for no side effects,
        // thus keys and values previously present in the trie were not affected:
        let sheKey = "she"
        let sellsKey = "sells"
        let n1 = sut._get(node: sut.root, key: sheKey, index: sheKey.startIndex)
        XCTAssertNotNil(n1)
        XCTAssertEqual(n1?.char, sheKey.last)
        XCTAssertEqual(n1?.value, 0)
        let n2 = sut._get(node: sut.root, key: sellsKey, index: sellsKey.startIndex)
        XCTAssertNotNil(n2)
        XCTAssertEqual(n2?.char, sellsKey.last)
        XCTAssertEqual(n2?.value, 1)
        assertCountValuesAreValid(root: sut.root)
    }
    
    func testPut_whenNodeIsNotNilAndKeyIsInTrieRootedAtNode_thenCombineExecutesAndValueForKeyIsSetToResultFromCombine() {
        var countOfExecutions = 0
        let combine: (Int, Int) -> Int = { _, latest in
            countOfExecutions += 1
            
            return latest + 10
        }
        whenContainsKeysFrom_SheSells_Sentence()
        let sheKey = "she"
        let newValue = Int.random(in: 10..<100)
        let oldValue = sut._get(node: sut.root, key: sheKey, index: sheKey.startIndex)!.value!
        let expectedValue = combine(oldValue, newValue)
        countOfExecutions = 0
        let prevCount = sut.root!.count
        
        sut.root = sut._put(node: sut.root, key: sheKey, value: newValue, index: sheKey.startIndex, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, 1)
        let n = sut._get(node: sut.root, key: sheKey, index: sheKey.startIndex)
        XCTAssertNotNil(n)
        XCTAssertEqual(sut.root?.count, prevCount)
        XCTAssertEqual(n?.value, expectedValue)
        
        // Let's also check for no side effects,
        // thus other key and value previously present in the trie was not affected:
        let sellsKey = "sells"
        let n1 = sut._get(node: sut.root, key: sellsKey, index: sellsKey.startIndex)
        XCTAssertNotNil(n1)
        XCTAssertEqual(n1?.value, 1)
        assertCountValuesAreValid(root: sut.root)
    }
    
    func testPut_whenCombineThrows_thenRethrows() {
        whenContainsKeysFrom_SheSells_Sentence()
        let combine: (Int, Int) throws -> Int = { _, _ in throw someError }
        let sheKey = "she"
        do {
            try sut.root = sut._put(node: sut.root, key: sheKey, value: Int.random(in: 0...10), index: sheKey.startIndex, uniquingKeysWith: combine)
            XCTFail("Didn't throw error")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - _remove(node:key:index) tests
    func testRemove_whenNodeIsNil_thenReturnsNodeAfterRemovalAsNilAndOldValueAsNil() throws {
        try XCTSkipIf(sut.root != nil, "node must be nil for this test")
        
        let key = givenKeys().randomElement()!
        let result = sut._remove(node: sut.root, key: key, index: key.startIndex)
        XCTAssertNil(result.nodeAfterRemoval)
        XCTAssertNil(result.oldValue)
    }
    
    func testRemove_whenNodeIsNotNilAndKeyIsNotInTrieRootedAtNode_thenReturnsNodeRootingToSameTrieAndOldValueAsNil() {
        let keys = givenKeys()
        try! whenContainsKeys(from: givenKeys())
        let key = keys.randomElement()! + ";"
        let expectedNode = sut.root!._clone()
        
        let result = sut._remove(node: sut.root, key: key, index: key.startIndex)
        assertAreEqualNodes(lhs: result.nodeAfterRemoval, rhs: expectedNode)
        XCTAssertNil(result.oldValue)
    }
    
    func testRemove_whenNodeIsNotNilAndKeyIsInTrieRootedAtNode_thenReturnsNodeRootingToTrieWithoutKeyAndOldValueForKey() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        for (expectedValue, key) in keys.enumerated() {
            let prevCount = sut.root!.count
            let result = sut._remove(node: sut.root, key: key, index: key.startIndex)
            XCTAssertEqual((sut.root?.count ?? 0), prevCount - 1)
            XCTAssertEqual(result.oldValue, expectedValue)
            sut.root = result.nodeAfterRemoval
            let n = sut._get(node: sut.root, key: key, index: key.startIndex)
            XCTAssertNil(n?.value)
            if expectedValue < keys.indices.last! {
                // we should also check for side effects not happening,
                // thus trie still has other keys and values still stored
                let remaninigKeys = keys[expectedValue + 1..<keys.endIndex]
                for (i, remaninigKey) in remaninigKeys.enumerated() {
                    let expectedRemainingValue = i + expectedValue + 1
                    let n1 = sut._get(node: sut.root, key: remaninigKey, index: remaninigKey.startIndex)
                    XCTAssertNotNil(n1)
                    XCTAssertEqual(n1?.value, expectedRemainingValue)
                }
            }
        }
        XCTAssertNil(sut.root)
    }
    
    // MARK: - _removeElementAt(node:rank:) tests
    func testRemoveElementAt_whenNodeIsNil_thenReturnsthenReturnsNodeAfterRemovalAsNilAndRemovedelementAsNil() throws {
        try XCTSkipIf(sut.root != nil, "node must be nil for this test")
        
        let result = sut._removeElementAt(node: sut.root, rank: 0)
        XCTAssertNil(result.nodeAfterRemoval)
        XCTAssertNil(result.removedElement)
        assertCountValuesAreValid(root: sut.root)
    }
    
    func testRemoveElementAt_whenNodeIsNotNil_thenReturnsRootNodeOfNewTrieAndRemovedElement() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let expectedResults = keys
            .enumerated()
            .sorted(by: { $0.element < $1.element })
            .map({ (key: $0.element, value: $0.offset) })
        let rank = Int.random(in: 0..<keys.endIndex)
        let expectedResult = expectedResults[rank]
        
        let prevCount = sut.root!.count
        let result = sut._removeElementAt(node: sut.root, rank: rank)
        sut.root = result.nodeAfterRemoval
        XCTAssertEqual(result.removedElement?.key, expectedResult.key)
        XCTAssertEqual(result.removedElement?.value, expectedResult.value)
        XCTAssertEqual(sut.root?.count, prevCount - 1)
        XCTAssertNil(sut._get(node: sut.root, key: expectedResult.key, index: expectedResult.key.startIndex)?.value)
        assertCountValuesAreValid(root: sut.root)
    }
    
    func testRemoveElementAt_whenNodeIsNotNil_AndRemovalMakesNodeEmpty_thenReturnsNodeAfterRemovalAsNilAndRemovedElement() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let expectedResults = keys
            .enumerated()
            .sorted(by: { $0.element < $1.element })
            .map({ (key: $0.element, value: $0.offset) })
        for idx in 0..<keys.endIndex {
            let prevCount = sut.root!.count
            let result = sut._removeElementAt(node: sut.root, rank: 0)
            sut.root = result.nodeAfterRemoval
            let expectedResult = expectedResults[idx]
            XCTAssertEqual(result.removedElement?.key, expectedResult.key)
            XCTAssertEqual(result.removedElement?.value, expectedResult.value)
            XCTAssertEqual(sut.root?.count ?? 0, prevCount - 1)
            XCTAssertNil(sut._get(node: sut.root, key: expectedResult.key, index: expectedResult.key.startIndex)?.value)
            assertCountValuesAreValid(root: sut.root)
        }
        XCTAssertNil(sut.root)
    }
    
    func testRemoveElementAt_whenNodeIsNotNilAndRankIsGreaterThenOrEqualToNodeCount_thenDoesntRemoveElements() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let expectedResults = keys
            .enumerated()
            .sorted(by: { $0.element < $1.element })
            .map({ (key: $0.element, value: $0.offset) })
        let rank = sut.root!.count + Int.random(in: 0..<10)
        let prevCount = sut.root!.count
        
        let result = sut._removeElementAt(node: sut.root, rank: rank)
        sut.root = result.nodeAfterRemoval
        XCTAssertEqual(sut.root?.count, prevCount)
        XCTAssertNil(result.removedElement)
        assertCountValuesAreValid(root: sut.root)
        for (key, value) in expectedResults {
            let n = sut._get(node: sut.root, key: key, index: key.startIndex)
            XCTAssertEqual(n?.value, value)
        }
    }
    
    func testRemoveElementAt_whenNodeIsNotNilAndRankIsLessThanZero_thenDoesntRemoveElements() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let expectedResults = keys
            .enumerated()
            .sorted(by: { $0.element < $1.element })
            .map({ (key: $0.element, value: $0.offset) })
        let rank = Int.random(in: -10..<0)
        let prevCount = sut.root!.count
        
        let result = sut._removeElementAt(node: sut.root, rank: rank)
        sut.root = result.nodeAfterRemoval
        XCTAssertEqual(sut.root?.count, prevCount)
        XCTAssertNil(result.removedElement)
        assertCountValuesAreValid(root: sut.root)
        for (key, value) in expectedResults {
            let n = sut._get(node: sut.root, key: key, index: key.startIndex)
            XCTAssertEqual(n?.value, value)
        }
    }
    
    // MARK: - _rank(node:key:index) tests
    func testRank_whenNodeIsNil_thenReturnsZero() throws {
        try XCTSkipIf(sut.root != nil, "node must be nil for this test")
        
        for key in givenKeys() {
            XCTAssertEqual(sut._rank(node: sut.root, key: key, index: key.startIndex), 0)
        }
    }
    
    func testRank_whenNodeIsNotNilAndKeyIsInTrieRootedAtNode_thenReturnsOrderOfKeyInTrie() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let orderedKeysInTrie = keys.sorted()
        for key in keys {
            let result = sut._rank(node: sut.root, key: key, index: key.startIndex)
            XCTAssertEqual(key, orderedKeysInTrie[result], "rank: \(result) - idx of key in orderd array: \(orderedKeysInTrie.firstIndex(of: key)!)")
        }
    }
    
    func testRank_whenNodeIsNotNilAndKeyIsGreaterThanGreatestKeyInTrieRootedAtNode_thenReturnsValueEqualsToCount() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let key = "zigzag"
        
        let result = sut._rank(node: sut.root, key: key, index: key.startIndex)
        XCTAssertEqual(result, sut.root?.count)
    }
    
    func testRank_whenNodeIsNotNilAndKeyIsSmallerThanSmallestKeyInTrieRootedAtNode_thenReturnsZero() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let key = "aspect"
        
        let result = sut._rank(node: sut.root, key: key, index: key.startIndex)
        XCTAssertEqual(result, 0)
    }
    
    func testRank_whenNodeIsNotNilAndKeyIsNotInTrieRootedAtNode_thenReturnsIndexOfInsertionInSortedKeys() {
        let keys = givenKeys()
        let sortedKeys = givenKeys().sorted()
        try! whenContainsKeys(from: keys)
        let key = "pretty"
        let expectedResult = (sortedKeys as NSArray).index(of: key, inSortedRange: NSRange(0..<keys.endIndex), options: .insertionIndex, usingComparator: {
            ($0 as! String).compare($1 as! String)
        })
        
        let result = sut._rank(node: sut.root, key: key, index: key.startIndex)
        XCTAssertEqual(result, expectedResult)
    }
    
    // MARK: - _rankForExistingKey(node:key:index:)
    func testRankForExistingKey_whenNodeIsNil_thenReturnsNil() throws {
        try XCTSkipIf(sut.root != nil, "node must be nil for this test")
        let key = givenKeys().randomElement()!
        XCTAssertNil(sut._rankForExistingKey(node: sut.root, key: key, index: key.startIndex))
    }
    
    func testRankForExistingKey_whenNodeIsNotNilAndKeyIsNotInTrieRootedAtNode_thenReturnsNil() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let key = "sea"
        XCTAssertNil(sut._rankForExistingKey(node: sut.root, key: key, index: key.startIndex))
    }
    
    func testRankForExistingKey_whenNodeIsNotNilAndKeyIsInTrieRootedAtNode_thenReturnsRankOfKey() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let expectedKeys = keys.sorted()
        for key in keys {
            let rank = sut._rankForExistingKey(node: sut.root, key: key, index: key.startIndex)
            XCTAssertEqual(rank, expectedKeys.firstIndex(of: key))
        }
    }
    
    // MARK: - _select(node:rank:) tests
    func testSelect_whenNodeIsNil_thenReturnsNil() throws {
        try XCTSkipIf(sut.root != nil, "node must be nil for this test")
        XCTAssertNil(sut._select(node: sut.root, rank: 0))
    }
    
    func testSelect_whenNodeIsNotNil_thenReturnsElementInTrieRootedAtNodeAtSpecifiedRank() {
        let keys = givenKeys()
        let sortedKeys = givenKeys().sorted()
        try! whenContainsKeys(from: keys)
        for rank in 0..<sut.root!.count {
            let (key, value) = sut._select(node: sut.root, rank: rank)!
            XCTAssertEqual(key, sortedKeys[rank])
            XCTAssertEqual(value, keys.firstIndex(of: key))
        }
    }
    
    func testSelect_whenNodeIsNotNilAndRankIsGreaterThanEqualToNodeCount_thenReturnsNil() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let nodeCount = sut.root!.count
        for rank in nodeCount..<(nodeCount + Int.random(in: 1...100)) {
            XCTAssertNil(sut._select(node: sut.root, rank: rank))
        }
    }
    
    // MARK: - _selectNode(node:rank:)
    func testSelectNode_whenNodeIsNil_thenReturnsNil() throws {
        try XCTSkipIf(sut.root != nil, "node must be nil for this test")
        let rank = Int.random(in: 0..<10)
        XCTAssertNil(sut._selectNode(node: sut.root, rank: rank))
    }
    
    func testSelectNode_whenNodeIsNotNilAndRankIsInRange_thenReturnsNodeForElementAtGivenRank() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let expectedResults = keys
            .enumerated()
            .sorted(by: { $0.element < $1.element })
            .map({ (key: $0.element, value: $0.offset) })
        for rank in 0..<keys.count {
            let n = sut._selectNode(node: sut.root, rank: rank)
            let expectedResult = expectedResults[rank]
            XCTAssertEqual(n?.value, expectedResult.value)
            XCTAssertEqual(n?.char, expectedResult.key.last)
        }
    }
    
    func testSelectNode_whenNodeIsNotNilAndRankIsGreaterThanOrEqualToRootCount_thenReturnsNil() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let rank = sut.root!.count + Int.random(in: 0..<10)
        XCTAssertNil(sut._selectNode(node: sut.root, rank: rank))
    }
    
    func testSelectNode_whenNodeIsNotNilAndRankIsLessThanZero_thenReturnsNil() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let rank = Int.random(in: -10..<0)
        XCTAssertNil(sut._selectNode(node: sut.root, rank: rank))
    }
    
    // MARK: - _forEach(node:prefix:body:) tests
    func testForEach_whenNodeIsNil_thenBodyDoesntExecutes() throws {
        try XCTSkipIf(sut.root != nil, "node must be nil for this test")
        
        var countOfExecutions = 0
        let body: ((String, Int)) -> Void = { _ in countOfExecutions += 1 }
        
        sut._forEach(node: sut.root, body: body)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testForEach_whenNodeIsNotNil_thenExecutesBodyOnEveryElementInTrieRootedAtNodeRespectingKeysOrder() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let expectedResult = Array(keys.enumerated())
            .sorted(by: { $0.element < $1.element })
            .map({ (key: $0.element, value: $0.offset) })
        
        var result: Array<(key: String, value: Int)> = []
        sut._forEach(node: sut.root, body: { result.append($0) })
        guard
            result
                .elementsEqual(expectedResult,
                               by: { $0.key == $1.key && $0.value == $1.value }
                )
        else {
            XCTFail("\(result) is different from: \(expectedResult)")
            return
        }
    }
    
    func testForEach_whenBodyThrows_thenRethrows() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        do {
            try sut._forEach(node: sut.root, body: { _ in throw someError })
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - _forEach(node:prefix:matching:at:body:)
    func testForEachMatchingPattern_whenNodeIsNil_thenBodyNeverExecutes() throws {
        try XCTSkipIf(sut.root != nil, "node must be nil for this test")
        
        let pattern = "."
        var countOfExecutions = 0
        let body: ((String, Int)) -> Void = { _ in countOfExecutions += 1 }
        sut._forEach(node: sut.root, matching: pattern, at: pattern.startIndex, body: body)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testForEachMatchingPattern_whenNodeINotNilAndPatternDoesntMatchAnyKeyInTrieRootedAtNode_thenBodyNeverExecutes() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let pattern = "he"
        var countOfExecutions = 0
        let body: ((String, Int)) -> Void = { _ in countOfExecutions += 1 }
        
        sut._forEach(node: sut.root, matching: pattern, at: pattern.startIndex, body: body)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testForEachMatchingPattern_whenNodeINotNilAndPatternMatchesSomeKeysInTrieRootedAtNode_thenBodyExecutesWithThoseKeyValuePairs() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        var pattern = "she"
        var matchedElements: Array<(String, Int)> = []
        
        sut._forEach(node: sut.root, matching: pattern, at: pattern.startIndex, body: { matchedElements.append($0) })
        for (resultKey, resultValue) in matchedElements {
            XCTAssertEqual(keys[resultValue], resultKey)
            XCTAssertTrue(resultKey.hasPrefix(pattern))
        }
        
        // let's also do the test with a pattern containing wildcard characters
        matchedElements.removeAll(keepingCapacity: true)
        pattern = "sh."
        var matchedPrefix = pattern.dropLast()
        
        sut._forEach(node: sut.root, matching: pattern, at: pattern.startIndex, body: { matchedElements.append($0) })
        for (resultKey, resultValue) in matchedElements {
            XCTAssertEqual(keys[resultValue], resultKey)
            XCTAssertTrue(resultKey.hasPrefix(matchedPrefix))
        }
        
        matchedElements.removeAll(keepingCapacity: true)
        pattern = ".he"
        matchedPrefix = pattern.dropFirst()
        sut._forEach(node: sut.root, matching: pattern, at: pattern.startIndex, body: { matchedElements.append($0) })
        for (resultKey, resultValue) in matchedElements {
            XCTAssertEqual(keys[resultValue], resultKey)
            XCTAssertTrue(resultKey.dropFirst().hasPrefix(matchedPrefix))
        }
    }
    
    func testForEachMatchingPattern_whenBodyThrows_thenRethrows() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let pattern = "she"
        let body: ((String, Int)) throws -> Void = { _ in throw someError }
        
        do {
            try sut._forEach(node: sut.root, matching: pattern, at: pattern.startIndex, body: body)
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - _filter(node:prefix:by:) tests
    func testFilter_whenNodeIsEmpty_thenIsIncludedNeverExecutesAndReturnsNil() throws {
        try XCTSkipIf(sut.root != nil, "node must be nil for this test")
        var countOfExecutions = 0
        let isIncluded: ((String, Int)) -> Bool = { _ in
            countOfExecutions += 1
            
            return true
        }
        XCTAssertNil(sut._filter(node: sut.root, by: isIncluded))
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testFilter_whenNodeIsNotEmpty_thenIsIncludedExecutesOnEveryElementOfTireRootedAtNodeAndReturnsRootNodeOfFilteredTrie() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        var countOfExecutions = 0
        let isIncluded: ((String, Int)) -> Bool = {
            countOfExecutions += 1
            
            return $0.1 % 2 == 0
        }
        let expectedResult = Array(keys.enumerated())
            .sorted(by: { $0.element < $1.element })
            .map({ (key: $0.element, value: $0.offset) })
            .filter(isIncluded)
        countOfExecutions = 0
        
        sut.root = sut._filter(node: sut.root, by: isIncluded)
        XCTAssertEqual(countOfExecutions, keys.count)
        XCTAssertEqual(sut.root?.count, expectedResult.count)
        for (key, value) in expectedResult {
            XCTAssertEqual(sut._get(node: sut.root, key: key, index: key.startIndex)?.value, value)
        }
    }
    
    func testFilter_whenIsIncludedThrows_thenRethrows() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        do {
            sut.root = try sut._filter(node: sut.root, by: { _ in throw someError })
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - _mapValues(node:transform:)
    func testMapValues_whenNodeIsNil_thenTransformNeverExecutesAndReturnsNil() throws {
        try XCTSkipIf(sut.root != nil, "node must be nil for this test")
        var countOfExecutions = 0
        let transform: (Int) -> Double = {
            countOfExecutions += 1
            
            return Double($0)
        }
        
        XCTAssertNil(sut._mapValues(node: sut.root, transform: transform))
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testMapValues_whenNodeIsNotNil_thenTransformExecutesForAllValuesInTrieRootedAndNodeAndReturnsRootNodeOfTrieWithMappedValues() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        var countOfExecutions = 0
        let transform: (Int) -> Double = {
            countOfExecutions += 1
            
            return Double($0)
        }
        let expectedResult = Array(keys.enumerated())
            .map({ (key: $0.element, value: transform($0.offset)) })
            .sorted(by: { $0.key < $1.key })
        countOfExecutions = 0
        
        let transformed = sut._mapValues(node: sut.root, transform: transform)
        XCTAssertNotNil(transformed)
        XCTAssertEqual(countOfExecutions, keys.count)
        XCTAssertEqual(transformed?.count, sut.root?.count)
        var transformedTrie = ThreeWaysTrie<Double>()
        transformedTrie.root = transformed
        var result: Array<(key: String, value: Double)> = []
        transformedTrie._forEach(node: transformedTrie.root, body: { result.append($0) })
        XCTAssertTrue(result.elementsEqual(expectedResult, by: { $0.key == $1.key && $0.value == $1.value }))
    }
    
    func testMapValues_whenTranformThrows_thenRethorws() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        do {
            let _ = try sut._mapValues(node: sut.root, transform: { _ in throw someError })
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - _compactMapValues(node:transform:) tests
    func testCompactMapValues_whenNodeIsNil_thenTransformNeverExecutesAndReturnsNil() throws {
        try XCTSkipIf(sut.root != nil, "node must be nil for this test")
        var countOfExecutions = 0
        let transform: (Int) -> Double? = { _ in
            countOfExecutions += 1
            
            return nil
        }
        XCTAssertNil(sut._compactMapValues(node: sut.root, transform: transform))
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testCompactMapValues_whenNodeIsNotNil_thenTransformExecutesOnEveryNodeAndReturnsTrieRootedAtNodeWithCompactMappedValues() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        var countOfExecutions = 0
        let transform: (Int) -> Double? = {
            countOfExecutions += 1
            
            return $0 % 2 == 0 ? Double($0) : nil
        }
        let expectedResult: Array<(key: String, value: Double)> = givenKeys().enumerated()
            .compactMap({
                guard let v = transform($0.offset) else { return nil }
            
                return ($0.element, v)
            })
            .sorted(by: {
                $0.key < $1.key
            })
        countOfExecutions = 0
        var otherTrie = ThreeWaysTrie<Double>()
        otherTrie.root = sut._compactMapValues(node: sut.root, transform: transform)
        XCTAssertEqual(countOfExecutions, keys.count)
        var result: Array<(key: String, value: Double)> = []
        otherTrie._forEach(node: otherTrie.root, body: { result.append($0) })
        XCTAssertTrue(result.elementsEqual(expectedResult, by: { $0.key == $1.key && $0.value == $1.value }))
        assertCountValuesAreValid(root: otherTrie.root)
    }
    
    func testCompactMapValues_whenNodeIsNotNilAndTransformReturnsNilForEveryElementInTrieRootedAtNode_thenReturnsNil() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        XCTAssertNil(sut._compactMapValues(node: sut.root, transform: { (Int) -> Double? in nil }))
    }
    
    func testCompactMapValues_whenTransformThrows_thenRethrows() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        do {
            let _ = try sut._compactMapValues(node: sut.root) { (Int) -> Double? in
                throw someError
            }
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - _traverse(traversal:_:) tests
    func testTraverse_whenRootIsNil_thenBodyNeverExecutes() throws {
        try XCTSkipIf(sut.root != nil, "root must be nil for this test")
        for traversal in ThreeWaysTrie<Int>._Traversal.allCases {
            var countOfExecutions = 0
            sut._traverse(traversal: traversal) { _, _, _ in
                countOfExecutions += 1
            }
            XCTAssertEqual(countOfExecutions, 0)
        }
    }
    
    func testTraverse_whenRootIsNotNilAndStopIsNeverSetToTrueInBody_thenBodyExecutesOnEveryNodeInTrie() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let keysAndElements = keys.enumerated().map({ (key: $0.element, value: $0.offset) })
        for traversal in ThreeWaysTrie<Int>._Traversal.allCases {
            var result: Array<(key: String, value: Int)> = []
            sut._traverse(traversal: traversal) { _, key, node in
                guard
                    let v = node.value
                else { return }
                result.append((key, v))
            }
            guard
                result.count == keysAndElements.count
            else {
                XCTFail("Not produced the same amount of elements in trie for traversal: \(traversal)")
                continue
            }
            
            for (resultKey, resultValue) in result {
                XCTAssertNotNil(keysAndElements.firstIndex(where: { $0.key == resultKey && $0.value == resultValue }))
            }
        }
    }
    
    func testTraverse_whenRootIsNotNilAndStopIsSetToTrueInBody_thenBodyDoesntExecutesAnymoreAndTraversalEnds() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        for traversal in ThreeWaysTrie<Int>._Traversal.allCases {
            let keyToStopAt = keys.randomElement()!
            weak var lastNodeVisited: Node? = nil
            sut._traverse(traversal: traversal, { stop, prefix, node in
                guard
                    prefix == keyToStopAt
                else { return }
                
                lastNodeVisited = node
                stop = true
            })
            XCTAssertEqual(lastNodeVisited?.char, keyToStopAt.last)
        }
    }
    
    func testTraverseInOrder_whenRootIsNotNil_thenVisitsNodesInOrderLeftMidRight() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let expectedResult = keys.sorted()
        var result: Array<String> = []
        sut._traverse(traversal: .inOrder, { _, prefix, node in
            guard
                node.value != nil
            else { return }
            
            result.append(prefix)
        })
        XCTAssertEqual(result, expectedResult)
    }
    
    func testTraverseInReverseInOrder_whenRootIsNotNil_thenVisitsNodesInReverseInOrderRightMidLeft() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let expectedResult = keys.sorted(by: >)
        var result: Array<String> = []
        sut._traverse(traversal: .reverseInOrder, { _, prefix, node in
            guard
                node.value != nil
            else { return }
            
            result.append(prefix)
        })
        XCTAssertEqual(result, expectedResult)
    }
    
    func testTraverseInPreOrder_whenRootIsNotNil_thenVisitsNodesInPreOrderMidLeftRight() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let expectedResult = ["she", "shoreline", "sells", "seashells", "by", "the"]
        var result: Array<String> = []
        sut._traverse(traversal: .preOrder, { _, prefix, node in
            guard
                node.value != nil
            else { return }
            
            result.append(prefix)
        })
        XCTAssertEqual(result, expectedResult)
    }
    
    func testTraverse_whenBodyThrows_thenRethrows() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        for traversal in ThreeWaysTrie<Int>._Traversal.allCases {
            do {
                try sut._traverse(traversal: traversal, { _, _, _ in throw someError })
                XCTFail("Didn't rethrows on traversal. \(traversal)")
            } catch {
                XCTAssertEqual(error as NSError, someError)
            }
        }
    }
    
}
