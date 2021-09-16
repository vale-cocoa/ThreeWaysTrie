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
    
    // MARK: - Equatable conformance tests
    func testEqualWhenSameInstance_thenReturnsTrue() {
        let rhs = sut!
        XCTAssertTrue(sut === rhs)
        XCTAssertEqual(sut, rhs)
    }
    
    func testEqual_whenDifferentInstancesAndSubNodesAreAllNil_thenReturnsAccordinglyToCharValueAndCountEquality() {
        sut.value = 1
        sut.count = 1
        var rhs = Node(char: sut.char)
        XCTAssertFalse(sut === rhs)
        rhs.value = sut.value
        rhs.count = sut.count
        
        // when char, value and count are equal, then returns true
        XCTAssertEqual(sut, rhs)
        
        // when value are different, then returns false
        rhs.value! += 1
        XCTAssertNotEqual(sut, rhs)
        
        // when count are different, then returns false
        rhs.value = sut.value
        rhs.count += 1
        XCTAssertNotEqual(sut, rhs)
        
        // when char are different, then returns false
        sut = Node(char: Character(Unicode.Scalar(UInt8.random(in: 0..<128))))
        sut.value = Int.random(in: 0..<10)
        sut.count = Int.random(in: 0..<10)
        rhs = Node(char: Character(Unicode.Scalar(UInt8.random(in: 128...UInt8.max))))
        sut.value = Int.random(in: 1...100)
        rhs.value = sut.value
        sut.count = Int.random(in: 0..<100)
        rhs.count = sut.count
        XCTAssertNotEqual(sut, rhs)
    }
    
    func testEqual_whenDifferentInstancesAndCharValueAndCountAreEqual_thenReturnsAccordinglyToLeftMidAndRightValues() {
        let subNodeA = Node(char: Character(Unicode.Scalar(UInt8.random(in: 0..<128))))
        let subNodeB = Node(char: Character(Unicode.Scalar(UInt8.random(in: 128...UInt8.max))))
        let rhs = Node(char: sut.char)
        
        // when left are equal, then returns true
        sut.left = subNodeA
        rhs.left = subNodeA
        XCTAssertEqual(sut, rhs)
        
        // when either left is nil and other left is not nil, then returns false
        sut.left = nil
        XCTAssertNotEqual(sut, rhs)
        sut.left = subNodeB
        rhs.left = nil
        XCTAssertNotEqual(sut, rhs)
        
        // when left are not equal, then returns false
        rhs.left = subNodeA
        XCTAssertNotEqual(sut, rhs)
        
        // when left are same and mid are same, then returns true
        sut.left = subNodeA
        sut.mid = subNodeB
        rhs.mid = subNodeB
        XCTAssertEqual(sut, rhs)
        
        // when left are same, either mid is nil and other mid is not nil, then returns false
        sut.mid = nil
        XCTAssertNotEqual(sut, rhs)
        sut.mid = subNodeA
        rhs.mid = nil
        XCTAssertNotEqual(sut, rhs)
        
        // when left are equal, mid are not equal, then returns false
        rhs.mid = subNodeB
        XCTAssertNotEqual(sut, rhs)
        
        // when left are same, mid are same, and right are same, then returns true
        sut.mid = subNodeB
        sut.right = subNodeA
        rhs.right = subNodeA
        XCTAssertEqual(sut, rhs)
        
        // when left are same, mid are same, either right is nil and
        // other right is not nil, then returns false
        sut.right = nil
        XCTAssertNotEqual(sut, rhs)
        sut.right = subNodeA
        rhs.right = nil
        XCTAssertNotEqual(sut, rhs)
    }
    
    // MARK: - Hashable conformance
    func testHashable() {
        // We use a swift Set to check for hashable conformance
        var set: Set<Node> = []
        let firstKeys = givenKeys()
        let otherKeys = firstKeys + ["at", "low", "cost"]
        try! whenContainsKeys(from: firstKeys)
        set.insert(sut)
        
        // Attempting to insert the same instance fails
        var other = sut!
        XCTAssertFalse(set.insert(other).inserted)
        
        // As well as attempting a copy of it
        other = sut._clone()
        XCTAssertFalse(set.insert(other).inserted)
        
        // Inserting another one which is different from the one already in set,
        // succeeds
        try! whenContainsKeys(from: otherKeys)
        XCTAssertTrue(set.insert(sut).inserted)
        
        // Attempting to insert a copy of it fails:
        other = sut._clone()
        XCTAssertFalse(set.insert(other).inserted)
    }
    
    // MARK: - Codable conformance
    func testEncodeThanDecode() {
        try! whenContainsKeys(from: givenKeys())
        
        do {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            let data = try encoder.encode(sut)
            let decoded = try decoder.decode(Node.self, from: data)
            assertAreEqualNodesButNotSameInstance(lhs: sut, rhs: decoded)
        } catch {
            XCTFail("Thrown error while encoding/decoding: \(error.localizedDescription)")
        }
    }
    
    func testDecode_whenMalformedJSON_thenThrowsError() throws {
        guard
            let data = try? JSONSerialization.data(withJSONObject: malformedJSON, options: .prettyPrinted)
        else { throw XCTSkip("Couldn't create JSON data from: \(malformedJSON)") }
        
        let decoder = JSONDecoder()
        do {
            let _ = try decoder.decode(Node.self, from: data)
            XCTFail("Didn't throw error")
        } catch {
            XCTAssertEqual(ThreeWaysTrie<Int>.Node.Error.emptyCharacter as NSError, error as NSError)
        }
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
        let expectedResult = ["she", "sells", "seashells", "seashore", "by", "the"]
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

// MARK: - Helpers
fileprivate final class WrappedValue: NSCopying {
    var value: NSArray
    
    init(_ value: Array<Any>) {
        self.value = value as NSArray
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let clone = WrappedValue(value.copy(with: zone) as! Array)
        
        return clone
    }
    
}

fileprivate let malformedJSON: [String : Any] = [
    "char" : "" as Any,
    "value" : 1 as Any,
    "count" : 1 as Any,
]
