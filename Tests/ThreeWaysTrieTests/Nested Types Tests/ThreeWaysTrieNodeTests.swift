//
//  ThreeWaysTrieNodeTests.swift
//  ThreeWaysTrieTests
//
//  Created by Valeriano Della Longa on 2021/09/05.
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

final class ThreeWaysTrieNodeTests: XCTestCase {
    typealias Node = ThreeWaysTrie<Int>.Node
    
    var sut: Node!
    
    override func setUp() {
        super.setUp()
        
        sut = Node(char: Character(Unicode.Scalar(UInt8.random(in: 0...UInt8.max))))
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    // MARK: - Given
    func givenRandomScalar() throws -> Unicode.Scalar {
        for _ in 0..<100 {
            let value = UInt16.random(in: 0...UInt16.max)
            guard
                let scalar = Unicode.Scalar(value)
            else { continue }
            
            return scalar
        }
        
        throw XCTSkip("Couldn't form a valid random unicode scalar")
    }
    
    // MARK: - When
    func whenContainsKeys(from keys: Array<String>) throws {
        // Leverages on _put(node:key:value:index:uniquingKeysWith:) method
        guard
            !keys.isEmpty
        else {
            throw XCTSkip("keys is empty")
        }
        
        var trie = ThreeWaysTrie<Int>()
        for (value, key) in keys.enumerated() {
            trie.root = trie._put(node: trie.root, key: key, value: value, index: key.startIndex, uniquingKeysWith: {_, latest in latest })
        }
        sut = trie.root!
    }
    
    // MARK: - Tests
    func testInit() throws {
        let scalar = try givenRandomScalar()
        let char = Character(scalar)
        sut = Node(char: char)
        
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.char, char)
        XCTAssertNil(sut.value)
        XCTAssertEqual(sut.count, 0)
        XCTAssertNil(sut.left)
        XCTAssertNil(sut.mid)
        XCTAssertNil(sut.right)
        XCTAssertTrue(sut._isEmpty)
    }
    
    func testIsEmpty() throws {
        // when value, left, mid and right are all nil,
        // then returns true
        try XCTSkipIf(sut.value != nil || sut.left != nil || sut.mid != nil || sut.right != nil, "value, left, mid and right must all be nil for this tests")
        XCTAssertTrue(sut._isEmpty)
        
        // when value is not nil, then returns false
        sut.value = 1
        XCTAssertFalse(sut._isEmpty)
        
        let otherNode = Node(char: Character(Unicode.Scalar(UInt8.random(in: 0...UInt8.max))))
        otherNode.value = 1
        sut.value = nil
        
        // when value is nil and either left, mid or right is not nil, then returns false
        sut.left = otherNode
        XCTAssertFalse(sut._isEmpty)
        
        sut.left = nil
        sut.mid = otherNode
        XCTAssertFalse(sut._isEmpty)
        
        sut.mid = nil
        sut.right = otherNode
        XCTAssertFalse(sut._isEmpty)
    }
    
    func testClone() {
        // This will also test copy(with:) since it leverages on that method
        let l = Node(char: Character(Unicode.Scalar.init(UInt8.random(in: 0...UInt8.max))))
        l.value = Int.random(in: 0..<1000)
        l.count = 1
        let m = Node(char: Character(Unicode.Scalar.init(UInt8.random(in: 0...UInt8.max))))
        m.value = Int.random(in: 0..<1000)
        m.count = 1
        let r = Node(char: Character(Unicode.Scalar.init(UInt8.random(in: 0...UInt8.max))))
        r.value = Int.random(in: 0..<1000)
        r.count = 1
        sut.value = Int.random(in: 0..<1000)
        sut.left = l
        sut.mid = m
        sut.right = r
        sut.count = 4
        
        let cp = sut._clone()
        XCTAssertNotNil(cp)
        XCTAssertFalse(sut === cp)
        assertAreEqualNodesButNotSameInstance(lhs: sut, rhs: cp)
    }
    
    func testCopy_whenValueIsReferenceTypeConformingToNSCopying_thenDoesDeepCopyOfValue() {
        let node = ThreeWaysTrie<WrappedValue>.Node(char: Character(Unicode.Scalar(UInt8.random(in: 0...UInt8.max))))
        node.value = WrappedValue([1])
        let clone = node.copy() as! ThreeWaysTrie<WrappedValue>.Node
        
        XCTAssertFalse(node === clone)
        XCTAssertFalse(node.value === clone.value)
        XCTAssertFalse(node.value?.value === clone.value?.value)
    }
    
    func testUpdateCount() {
        let otherNode = Node(char: Character(Unicode.Scalar(UInt8.random(in: 0...UInt8.max))))
        otherNode.value = 1
        otherNode.count = 1
        
        var prevCount = sut.count
        sut.value = 1
        
        sut._updateCount()
        XCTAssertGreaterThan(sut.count, prevCount)
        
        prevCount = sut.count
        sut.left = otherNode
        
        sut._updateCount()
        XCTAssertGreaterThan(sut.count, prevCount)
        
        otherNode.count += 1
        prevCount = sut.count
        
        sut._updateCount()
        XCTAssertGreaterThan(sut.count, prevCount)
        
        prevCount = sut.count
        sut.left = nil
        
        sut._updateCount()
        XCTAssertLessThan(sut.count, prevCount)
        
        prevCount = sut.count
        sut.mid = otherNode
        
        sut._updateCount()
        XCTAssertGreaterThan(sut.count, prevCount)
        
        otherNode.count += 1
        prevCount = sut.count
        
        sut._updateCount()
        XCTAssertGreaterThan(sut.count, prevCount)
        
        sut.mid = nil
        prevCount = sut.count
        
        sut._updateCount()
        XCTAssertLessThan(sut.count, prevCount)
        
        sut.right = otherNode
        prevCount = sut.count
        
        sut._updateCount()
        XCTAssertGreaterThan(sut.count, prevCount)
        
        otherNode.count += 1
        prevCount = sut.count
        
        sut._updateCount()
        XCTAssertGreaterThan(sut.count, prevCount)
        
        sut.right = nil
        prevCount = sut.count
        
        sut._updateCount()
        XCTAssertLessThan(sut.count, prevCount)
        
        prevCount = sut.count
        sut.value = nil
        
        sut._updateCount()
        XCTAssertLessThan(sut.count, prevCount)
    }
        
    // MARK: - Traversals Tests
    func testTraversals_whenBodyThrows_thenRethrows() {
        let body: (inout Bool, String, Node) throws -> Void = { _, _, _ in throw someError }
        do {
            try sut._inOrderVisit(body)
            XCTFail("Didn't rethrow for _inOrderVisit(prefix:_:)")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
        
        do {
            try sut._reverseInOrderVisit(body)
            XCTFail("Didn't rethrow for _reverseInOrderVisit(prefix:_:)")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
        
        do {
            try sut._preOrderVisit(body)
            XCTFail("Didn't rethrow for _preOrderVisit(prefix:_:)")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    func testTraversals_whenRootIsNotNilAndStopIsNeverSetToTrueInBody_thenBodyExecutesOnEveryNodeInTrieAndReturnsFalse() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let expectedElements = keys.enumerated().map({ (key: $0.element, value: $0.offset) })
        
        var elementsCollected: Array<(key: String, value: Int)> = []
        var result = sut._inOrderVisit() { _, key, node in
            guard
                let v = node.value
            else { return }
            elementsCollected.append((key, v))
        }
        XCTAssertFalse(result)
        if elementsCollected.count == expectedElements.count {
            for (resultKey, resultValue) in elementsCollected {
                XCTAssertNotNil(expectedElements.firstIndex(where: { $0.key == resultKey && $0.value == resultValue }))
            }
        } else {
            XCTFail("Didn't execute body on every node for _inOrderVisit(prefix:_:)")
        }
        
        elementsCollected.removeAll(keepingCapacity: true)
        result = sut._reverseInOrderVisit() { _, key, node in
            guard
                let v = node.value
            else { return }
            elementsCollected.append((key, v))
        }
        XCTAssertFalse(result)
        if elementsCollected.count == expectedElements.count {
            for (resultKey, resultValue) in elementsCollected {
                XCTAssertNotNil(expectedElements.firstIndex(where: { $0.key == resultKey && $0.value == resultValue }))
            }
        } else {
            XCTFail("Didn't execute body on every node for _reverseInOrderVisit(prefix:_:)")
        }
        
        elementsCollected.removeAll(keepingCapacity: true)
        result = sut._preOrderVisit() { _, key, node in
            guard
                let v = node.value
            else { return }
            elementsCollected.append((key, v))
        }
        XCTAssertFalse(result)
        if elementsCollected.count == expectedElements.count {
            for (resultKey, resultValue) in elementsCollected {
                XCTAssertNotNil(expectedElements.firstIndex(where: { $0.key == resultKey && $0.value == resultValue }))
            }
        } else {
            XCTFail("Didn't execute body on every node for _preOrderVisit(prefix:_:)")
        }
    }
    
    func testTraversals_whenStopIsSetToTrueInBody_thenTraversalStopsAndReturnsTrue() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let keyToStopAt = keys.randomElement()!
        var result: String? = nil
        let body: (inout Bool, String, Node) -> Void = { stop, key, _ in
            guard
                key == keyToStopAt
            else { return }
            
            result = key
            stop = true
        }
        
        XCTAssertTrue(sut._inOrderVisit(body))
        XCTAssertEqual(result, keyToStopAt)
        
        result = nil
        XCTAssertTrue(sut._reverseInOrderVisit(body))
        XCTAssertEqual(result, keyToStopAt)
        
        result = nil
        XCTAssertTrue(sut._preOrderVisit(body))
        XCTAssertEqual(result, keyToStopAt)
    }
    
    func testInOrderVisit_traversesNodesInOrder() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let expectedResult = keys.sorted()
        var result: Array<String> = []
        sut._inOrderVisit() { _, prefix, node in
            guard
                node.value != nil
            else { return }
            
            result.append(prefix)
        }
        XCTAssertEqual(result, expectedResult)
    }
    
    func testReverseInOrderVisit_traversesNodesInRevereseInOrder() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let expectedResult = keys.sorted(by: >)
        var result: Array<String> = []
        sut._reverseInOrderVisit() { _, prefix, node in
            guard
                node.value != nil
            else { return }
            
            result.append(prefix)
        }
        XCTAssertEqual(result, expectedResult)
    }
    
    func testPreOrderVisit_traversesNodesInPreOrder() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let expectedResult = ["she", "shoreline", "sells", "seashells", "by", "the"]
        var result: Array<String> = []
        sut._preOrderVisit() { _, prefix, node in
            guard
                node.value != nil
            else { return }
            
            result.append(prefix)
        }
        XCTAssertEqual(result, expectedResult)
    }
    
    // MARK: - _floor(key:index:prefix:) tests
    func testFloor_whenKeyIsSmallerThanSmallestKeyInTrieRootedAtNode_thenReturnsNil() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let key = "bitter"
        XCTAssertNil(sut._floor(key: key, index: key.startIndex))
    }
    
    func testFloor_whenKeyIsLargerThanLargestKeyInTrieRootedAtNode_thenReturnsLargestKeyInTrieRootedAtNode() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let key = "tremendous"
        XCTAssertEqual(sut._floor(key: key, index: key.startIndex), keys.sorted().last)
    }
    
    func testFloor_whenKeyIsNotInTrieRootedAtNodeAndKeyIsBetweenTwoKeysInTrieRootedAtNode_thenReturnsSmallestOfTheTwoContainedKeys() {
        let keys = givenKeys()
        let sortedKeys = keys.sorted()
        try! whenContainsKeys(from: keys)
        for expectedKey in sortedKeys {
            let key = expectedKey + "z"
            XCTAssertEqual(sut._floor(key: key, index: key.startIndex), expectedKey)
        }
    }
    
    func testFloor_whenKeyIsInTrieRootedAtNode_thenReturnsKey() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        for expectedKey in keys {
            XCTAssertEqual(sut._floor(key: expectedKey, index: expectedKey.startIndex), expectedKey)
        }
    }
    
    func testFloor_whenKeyIsAPrefixOfAContainedKey_thenReturnsTheContainedKeyImmediatetlyBeforeThanTheOneWithSuchPrefix() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let sortedKeys = keys.sorted()
        for idx in sortedKeys.indices.dropLast() {
            let key = String(sortedKeys[idx + 1].dropLast())
            let expectedKey = sortedKeys[idx]
            XCTAssertEqual(sut._floor(key: key, index: key.startIndex), expectedKey, "key to floor: \(key)")
        }
    }
    
    // MARK: - _ceiling(key:index:prefix:) tests
    func testCeiling_whenKeyIsLargerThanLargestKeyInTrieRootedAtNode_thenReturnsNil() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let key = "tremendous"
        XCTAssertNil(sut._ceiling(key: key, index: key.startIndex))
    }
    
    func testCeilining_whenKeyIsSmallerThanSmallestKeyInTrieRootedAtNode_thenReturnsSmallestKeyInTrieRootedAtNode() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        let key = "bitter"
        XCTAssertEqual(sut._ceiling(key: key, index: key.startIndex), keys.sorted().first)
    }
    
    func testCeiling_whenKeyIsNotInTrieRootedAtNodeAndIsBetweenTwoKeysInTrie_thenReturnsTheLargerKeyOfTheTwoContainedKeys() {
        let keys = givenKeys()
        let sortedKeys = keys.sorted()
        try! whenContainsKeys(from: keys)
        for expectedKey in sortedKeys {
            let key = String(expectedKey.dropLast())
            XCTAssertEqual(sut._ceiling(key: key, index: key.startIndex), expectedKey, "key was: \(key)")
        }
    }
    
    func testCeiling_whenKeyIsInTrieRootedAtNode_thenReturnsKey() {
        let keys = givenKeys()
        try! whenContainsKeys(from: keys)
        for expectedKey in keys {
            XCTAssertEqual(sut._ceiling(key: expectedKey, index: expectedKey.startIndex), expectedKey)
        }
    }
    
}



