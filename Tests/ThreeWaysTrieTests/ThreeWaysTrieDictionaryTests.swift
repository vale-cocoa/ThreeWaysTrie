//
//  ThreeWaysTrieDictionaryTests.swift
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

final class ThreeWaysTrieDictionaryTests: BaseTrieTestClass {
    typealias SutElement = ThreeWaysTrie<Int>.Element
    func testInitUniqueKeysWithValues() {
        var s: Array<(String, Int)> = []
        sut = ThreeWaysTrie(uniqueKeysWithValues: s)
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.isEmpty)
        
        s = givenKeys().enumerated().map({ ($0.element, $0.offset) })
        sut = ThreeWaysTrie(uniqueKeysWithValues: s)
        XCTAssertEqual(sut.count, s.count)
        for (key, expectedValue) in s {
            XCTAssertEqual(sut._get(node: sut.root, key: key, index: key.startIndex)?.value, expectedValue)
        }
    }
    
    // MARK: - init(_:uniquingKeysWith:) tests
    func testInitUniquingKeysWith_whenSequenceIsEmpty_thenCombineNeverExecutesAndReturnsEmptyTrie() {
        var countOfExecutions = 0
        let combine: (Int, Int) -> Int = {
            countOfExecutions += 1
            
            return $1
        }
        
        sut = ThreeWaysTrie([], uniquingKeysWith: combine)
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testInitUniquingKeysWith_whenSequenceIsNotEmptyAndContainsNoDuplicateKeys_thenCombineNeverExecutesAndReturnsTrieWithSequenceElements() {
        let seq = AnySequence(
            givenKeys()
                .enumerated()
                .map({ ($0.element, $0.offset) })
        )
        
        var countOfExecutions = 0
        let combine: (Int, Int) -> Int = {
            countOfExecutions += 1
            
            return $1
        }
        
        sut = ThreeWaysTrie(seq, uniquingKeysWith: combine)
        XCTAssertNotNil(sut)
        XCTAssertEqual(countOfExecutions, 0)
        var expectedCount = 0
        for (key, expectedValue) in seq {
            expectedCount += 1
            XCTAssertEqual(sut._get(node: sut.root, key: key, index: key.startIndex)?.value, expectedValue)
        }
        XCTAssertEqual(sut.count, expectedCount)
    }
    
    func testInitUniquingKeysWith_whenSequenceIsNotEmptyAndContainsDuplicateKeys_thenCombineExecutesOnSuchElementsAndReturnsTrieWithSequenceElementsCombined() {
        let seq = AnySequence<(String, Int)>(
            givenKeys()
                .enumerated()
                .flatMap({ (value, key) -> [(String, Int)] in
                    var elements: Array<(String, Int)> = [(key, value)]
                    if value % 2 == 0 {
                        elements.append((key, value + Int.random(in: 1...100)))
                    }
                    
                    return elements
                })
        )
        var countOfExecutions = 0
        let combine: (Int, Int) -> Int = {
            countOfExecutions += 1
            
            return $0 + $1
        }
        let expectedResult = Dictionary(seq, uniquingKeysWith: combine)
        let expectedCountOfExecutions = countOfExecutions
        countOfExecutions = 0
        
        sut = ThreeWaysTrie(seq, uniquingKeysWith: combine)
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.count, expectedResult.count)
        XCTAssertEqual(countOfExecutions, expectedCountOfExecutions)
        sut.forEach({
            XCTAssertEqual($0.value, expectedResult[$0.key])
        })
    }
    
    func testInitUniquingKeysWith_whenCombineThrows_thenRethrows() {
        let seq = AnySequence<(String, Int)>(
            givenKeys()
                .enumerated()
                .flatMap({ (value, key) -> [(String, Int)] in
                    var elements: Array<(String, Int)> = [(key, value)]
                    if value % 2 == 0 {
                        elements.append((key, value + Int.random(in: 1...100)))
                    }
                    
                    return elements
                })
        )
        do {
            sut = try ThreeWaysTrie(seq, uniquingKeysWith: { _, _ in throw someError })
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - init(grouping:by:) tests
    func testInitGroupingBy_whenValuesIsEmpty_thenKeyForValueNeverExectuesAndReturnsEmptyTrie() {
        var countOfExecutions = 0
        let keys = givenKeys()
        let keyForValue: (Int) -> String = {
            countOfExecutions += 1
            
            return keys.indices.contains($0) ? keys[$0] : "Undefined"
        }
        
        let trie = ThreeWaysTrie(grouping: Array<Int>(), by: keyForValue)
        XCTAssertNotNil(trie)
        XCTAssertTrue(trie.isEmpty)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testInitGroupingBy_whenValuesIsNotEmpty_thenKeyForValueExecutesForEachElementInValuesAndReturnsTrieWithValuesGroupedByKeys() {
        var countOfExecutions = 0
        let keys = givenKeys()
        let keyForValue: (Int) -> String = {
            countOfExecutions += 1
            
            return keys.indices.contains($0) ? keys[$0] : "Undefined"
        }
        let values = 0..<(keys.count + Int.random(in: 0..<10))
        let expectedResult = Dictionary(grouping: values, by: keyForValue)
        countOfExecutions = 0
        
        let trie = ThreeWaysTrie(grouping: values, by: keyForValue)
        XCTAssertNotNil(trie)
        XCTAssertEqual(trie.count, expectedResult.count)
        XCTAssertEqual(countOfExecutions, values.count)
        trie.forEach({
            XCTAssertEqual($0.value, expectedResult[$0.key])
        })
    }
    
    func testInitGroupingBy_whenKeyForValueThrows_thenRethrows() {
        do {
            let _ = try ThreeWaysTrie(grouping: 0..<100, by: { _ in throw someError })
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - ExpressibleByDictionaryLiteral conformance tests
    func testInitDictionaryLiteral() {
        sut = [:]
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.isEmpty)
        
        let expectedElements = [
            "she" : 0,
            "sells" : 1,
            "seashells" : 2,
            "by" : 3,
            "the" : 4,
            "shoreline" : 5
        ]
        
        sut = [
            "she" : 0,
            "sells" : 1,
            "seashells" : 2,
            "by" : 3,
            "the" : 4,
            "shoreline" : 5
        ]
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.count, expectedElements.count)
        sut.forEach({
            XCTAssertEqual($0.value, expectedElements[$0.key])
        })
    }
    
    // MARK: - key based subscripts tests
    func testSubscriptKeyGet_whenIsEmpty_thenReturnsNil() throws {
        try XCTSkipIf(!sut.isEmpty, "Trie must be empty for this test")
        for key in givenKeys() {
            XCTAssertNil(sut[key])
        }
    }
    
    func testSubscriptKeyGet_whenIsNotEmptyAndKeyIsNotInTrie_thenReturnsNil() {
        whenIsNotEmpty()
        let key = givenKeys().randomElement()! + "z"
        XCTAssertNil(sut[key])
    }
    
    func testSubscriptKeyGet_whenIsNotEmptyAndKeyIsInTrie_thenReturnsValueForKey() {
        whenIsNotEmpty()
        let expectedElements = Dictionary(uniqueKeysWithValues: givenKeys().enumerated().map({ ($0.element, $0.offset) }))
        for key in givenKeys() {
            XCTAssertEqual(sut[key], expectedElements[key])
        }
    }
    
    func testSubscriptKeySet_whenNewValueIsNotNil_thenSetsNewValueForKeyInTrie() {
        sut = ThreeWaysTrie()
        // When key is not in trie, then adds new element with key and new value
        for key in givenKeys() {
            let prevCount = sut.count
            let newValue = Int.random(in: 10...100)
            sut[key] = newValue
            XCTAssertEqual(sut[key], newValue)
            XCTAssertEqual(sut.count, prevCount + 1)
        }
        
        // When key is alreay in trie, then modify element with specified key to new value
        for key in givenKeys() {
            let prevCount = sut.count
            let newValue = Int.random(in: 101...200)
            sut[key] = newValue
            XCTAssertEqual(sut[key], newValue)
            XCTAssertEqual(sut.count, prevCount)
        }
    }
    
    func testSubscriptKeySet_whenNewValueIsNil_thenSetToNilValueForKeyInTrie() {
        sut = ThreeWaysTrie()
        // When key is not in trie, then nothing changes
        for key in givenKeys() {
            let prevCount = sut.count
            sut[key] = nil
            XCTAssertNil(sut[key])
            XCTAssertEqual(sut.count, prevCount)
        }
        
        whenIsNotEmpty()
        // When key is alreay in trie, then removes element with key
        for key in givenKeys() {
            let prevCount = sut.count
            sut[key] = nil
            XCTAssertNil(sut[key])
            XCTAssertEqual(sut.count, prevCount - 1)
        }
    }
    
    func testSubscriptSet_COW() {
        // when root is not nil and has not multiple string references,
        // then root is not copied
        whenIsNotEmpty()
        weak var prevRoot = sut.root
        sut["new"] = 10
        XCTAssertTrue(sut.root === prevRoot)
        sut["new"] = nil
        XCTAssertTrue(sut.root === prevRoot)
        
        // when root is not nil and has multiple strong references,
        // then root is copied before mutation
        var clone = sut!
        sut["new"] = 10
        XCTAssertFalse(sut.root === prevRoot)
        XCTAssertEqual(clone["new"], nil)
        
        clone = sut!
        prevRoot = sut.root
        sut["new"] = nil
        XCTAssertFalse(sut.root === prevRoot)
        XCTAssertEqual(clone["new"], 10)
    }
    
    func testSubscriptKeyDefaultGet() {
        // when key is not in trie, then returns defaultValue:
        sut = ThreeWaysTrie()
        for key in givenKeys() {
            var hasExecuted = false
            let expectedValue = Int.random(in: 0..<10)
            let defaultValue: () -> Int = {
                hasExecuted = true
                
                return expectedValue
            }
            
            XCTAssertEqual(sut[key, default: defaultValue()], expectedValue)
            XCTAssertTrue(hasExecuted)
        }
        
        // when key is in trie then returns stored value for key
        whenIsNotEmpty()
        let expectedElements = Dictionary(uniqueKeysWithValues: givenKeys()
                                            .enumerated()
                                            .map({ ($0.element, $0.offset) })
        )
        for key in givenKeys() {
            let notExpectedValue = Int.random(in: expectedElements.count..<100)
            var hasExecuted = false
            let defaultValue: () -> Int = {
                hasExecuted = true
                
                return notExpectedValue
            }
            
            XCTAssertEqual(sut[key, default: defaultValue()], expectedElements[key])
            XCTAssertFalse(hasExecuted)
        }
    }
    
    func testSubscriptKeyDefaultModify() {
        sut = ThreeWaysTrie()
        // when key is not in trie, then uses default value as base value for modification
        for key in givenKeys() {
            let baseValue = Int.random(in: 0..<10)
            let offset = Int.random(in: 10..<100)
            let expectedValue = baseValue + offset
            var hasExecuted = false
            let defaultValue: () -> Int = {
                hasExecuted = true
                
                return baseValue
            }
            
            sut[key, default: defaultValue()] += offset
            XCTAssertEqual(sut[key], expectedValue)
            XCTAssertTrue(hasExecuted)
        }
        
        // when key is in trie, then uses stored value as base value for modification
        whenIsNotEmpty()
        for key in givenKeys() {
            let baseValue = Int.random(in: sut.count..<100)
            let offset = Int.random(in: 10..<100)
            let expectedValue = sut[key]! + offset
            var hasExecuted = false
            let defaultValue: () -> Int = {
                hasExecuted = true
                
                return baseValue
            }
            
            sut[key, default: defaultValue()] += offset
            XCTAssertEqual(sut[key], expectedValue)
            XCTAssertFalse(hasExecuted)
        }
    }
    
    func testSubscriptKeyDefaultModify_COW() {
        // when root is not nil and has not multiple string references,
        // then root is not copied
        whenIsNotEmpty()
        weak var prevRoot = sut.root
        sut["new", default: 5] += 10
        XCTAssertTrue(sut.root === prevRoot)
        
        // when root is not nil and has multiple strong references,
        // then root is copied before mutation
        let clone = sut!
        sut["new", default: 5] += 10
        XCTAssertFalse(sut.root === prevRoot)
        XCTAssertEqual(clone["new"], 15)
    }
    
    // MARK: - index(forKey:) tests
    func testIndexForKey() {
        sut = ThreeWaysTrie()
        // when key is not in trie, then returns nil
        for key in givenKeys() {
            XCTAssertNil(sut.index(forKey: key))
        }
        whenIsNotEmpty()
        for inKey in givenKeys() {
            let key = inKey + "z"
            XCTAssertNil(sut.index(forKey: key), "key: \(key)")
        }
        
        // when key is in trie, then returns index of element with such key
        for key in givenKeys() {
            guard
                let idx = sut.index(forKey: key)
            else {
                XCTFail("Returned nil for key in trie: \(key)")
                continue
            }
            
            XCTAssertEqual(sut[idx].key, key)
        }
    }
    
    // MARK: - updateValue(_:forKey:) test
    func testUpdateValueForKey() {
        // when key is not in trie, then adds new element and returns nil
        sut = ThreeWaysTrie()
        for key in givenKeys() {
            let prevCount = sut.count
            let value = Int.random(in: 0..<10)
            XCTAssertNil(sut.updateValue(value, forKey: key))
            XCTAssertEqual(sut.count, prevCount + 1)
        }
        // when key is in trie, then updates value for key and returns old value
        for key in givenKeys() {
            let oldValue = sut[key]
            let newValue = Int.random(in: 10..<20)
            let prevCount = sut.count
            XCTAssertEqual(sut.updateValue(newValue, forKey: key), oldValue)
            XCTAssertEqual(sut[key], newValue)
            XCTAssertEqual(sut.count, prevCount)
        }
    }
    
    func testUpdateValueForKey_COW() {
        // when root is not nil and has not multiple string references,
        // then root is not copied
        whenIsNotEmpty()
        let key = givenKeys().randomElement()!
        weak var prevRoot = sut.root
        sut.updateValue(100, forKey: key)
        XCTAssertTrue(sut.root === prevRoot)
        
        // when root is not nil and has multiple strong references,
        // then root is copied before mutation
        let clone = sut!
        sut.updateValue(200, forKey: key)
        XCTAssertFalse(sut.root === prevRoot)
        XCTAssertEqual(clone[key], 100)
    }
    
    // MARK: - removeValue(forKey:) tests
    func testRemoveValueForKey() {
        // when key is not in trie, then returns nil and no element is removed
        sut = ThreeWaysTrie()
        for key in givenKeys() {
            XCTAssertNil(sut.removeValue(forKey: key))
            XCTAssertEqual(sut.count, 0)
        }
        whenIsNotEmpty()
        for inKey in givenKeys() {
            let key = inKey + "z"
            let prevCount = sut.count
            
            XCTAssertNil(sut.removeValue(forKey: key))
            XCTAssertEqual(sut.count, prevCount)
        }
        
        // when key is in trie, then removes element and returns its value
        for key in givenKeys() {
            let expectedValue = sut[key]
            let prevCount = sut.count
            
            XCTAssertEqual(sut.removeValue(forKey: key), expectedValue)
            XCTAssertEqual(sut.count, prevCount - 1)
        }
    }
    
    func testRemoveValueForKey_COW() {
        // when root is not nil and has not multiple string references,
        // then root is not copied
        whenIsNotEmpty()
        let key = givenKeys().randomElement()!
        weak var prevRoot = sut.root
        sut.removeValue(forKey: key)
        XCTAssertTrue(sut.root === prevRoot)
        
        // when root is not nil and has multiple strong references,
        // then root is copied before mutation
        whenIsNotEmpty()
        prevRoot = sut.root
        let clone = sut!
        sut.removeValue(forKey: key)
        XCTAssertFalse(sut.root === prevRoot)
        XCTAssertNotNil(clone[key])
    }
    
    func testRemoveAtIndex() {
        whenIsNotEmpty()
        while let idx = sut.indices.randomElement() {
            let expectedElement = sut[idx]
            let prevCount = sut.count
            
            let removedElement = sut.remove(at: idx)
            XCTAssertEqual(removedElement.key, expectedElement.key)
            XCTAssertEqual(removedElement.value, expectedElement.value)
            XCTAssertEqual(sut.count, prevCount - 1)
        }
    }
    
    func testRemoveAtIndex_COW() {
        // when root is not nil and has not multiple string references,
        // then root is not copied
        whenIsNotEmpty()
        let idx = sut.indices.randomElement()!
        weak var prevRoot = sut.root
        sut.remove(at: idx)
        XCTAssertTrue(sut.root === prevRoot)
        
        // when root is not nil and has multiple strong references,
        // then root is copied before mutation
        whenIsNotEmpty()
        prevRoot = sut.root
        let clone = sut!
        let prevElement = sut[idx]
        sut.remove(at: idx)
        XCTAssertFalse(sut.root === prevRoot)
        XCTAssertEqual(clone[idx].key, prevElement.key)
        XCTAssertEqual(clone[idx].value, prevElement.value)
    }
    
    // MARK: - removeAll() tests
    func testRemoveAll() {
        sut = ThreeWaysTrie()
        sut.removeAll()
        XCTAssertNil(sut.root)
        
        whenIsNotEmpty()
        sut.removeAll()
        XCTAssertNil(sut.root)
    }
    
    func testRemoveAll_COW() {
        // when root is not nil and has not multiple string references,
        // then dealloctes root
        whenIsNotEmpty()
        weak var prevRoot = sut.root
        sut.removeAll()
        XCTAssertNil(prevRoot)
        
        // when root is not nil and has multiple strong references,
        // then root is not deallocated
        whenIsNotEmpty()
        prevRoot = sut.root
        let clone = sut!
        sut.removeAll()
        XCTAssertNotNil(prevRoot)
        XCTAssertTrue(clone.root === prevRoot)
    }
    
    // MARK: - FP Dictionary methods tests
    
    // MARK: - mapValues(_:) tests
    func testMapValues_whenIsEmpty_thenTransfromNeverExecutesAndReturnsEmptyTrie() throws {
        try XCTSkipIf(!sut.isEmpty, "Trie must be empty for this test")
        var countOfExecutions = 0
        let transform: (Int) -> Double = {
            countOfExecutions += 1
            
            return Double($0)
        }
        
        let result = sut.mapValues(transform)
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testMapValues_whenIsNotEmpty_thenTransformExecutesOnEveryValueAndReturnsTrieWithMappedValues() {
        whenIsNotEmpty()
        var countOfExecutions = 0
        let transform: (Int) -> Double = {
            countOfExecutions += 1
            
            return Double($0)
        }
        
        let result = sut.mapValues(transform)
        XCTAssertEqual(result.count, sut.count)
        XCTAssertEqual(countOfExecutions, sut.count)
        for (key, value) in sut {
            let expectedValue = transform(value)
            XCTAssertEqual(result[key], expectedValue)
        }
    }
    
    func testMapValues_whenTransformThrows_thenRethrows() {
        whenIsNotEmpty()
        do {
            let _: ThreeWaysTrie<Double> = try sut.mapValues({ _ in throw someError })
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - compactMapValues(_:) tests
    func testCompactMapValues_whenIsEmpty_thenTransformNeverExecutesAndReturnsEmptyTrie() throws {
        try XCTSkipIf(!sut.isEmpty, "Trie must be empty for this test")
        var countOfExecutions = 0
        let transform: (Int) -> Double? = {
            countOfExecutions += 1
            
            return Double($0)
        }
        
        let result = sut.compactMapValues(transform)
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testCompactMapValues_whenIsNotEmptyAndTransformReturnsNilForEveryValueInTrie_thenTransformExecutesOnEveryElementOfTrieAndReturnsEmptyTrie() {
        whenIsNotEmpty()
        var capturedValues: Array<Int> = []
        let transform: (Int) -> Double? = {
            capturedValues.append($0)
            
            return nil
        }
        
        let result = sut.compactMapValues(transform)
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(capturedValues, sut!.map({ $0.value }))
    }
    
    func testCompactMapValues_whenIsNotEmptyAndTransformReturnsValueForSomeValuesInTrie_thenReturnsTrieWithTransformedValues() {
        whenIsNotEmpty()
        let transform: (Int) -> Double? = { $0 % 2 == 0 ? Double($0) : nil  }
        let expectedResult = Dictionary(uniqueKeysWithValues: sut!.map({ $0 }))
            .compactMapValues(transform)
        
        let result = sut.compactMapValues(transform)
        XCTAssertEqual(result.count, expectedResult.count)
        result.forEach({ XCTAssertEqual($0.value, expectedResult[$0.key]) })
    }
    
    func testCompactMapValues_whenTransformThrows_thenRethrows() {
        whenIsNotEmpty()
        do {
            let _: ThreeWaysTrie<Double> = try sut.compactMapValues({ _ in throw someError })
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - filter(_:) tests
    func testFilter_whenIsEmpty_thenIsIncludedNeverExecutesAndReturnsEmptyTrie() throws {
        try XCTSkipIf(!sut.isEmpty, "Trie must be empty for this test")
        var countOfExecutions = 0
        let isIncluded: (SutElement) -> Bool = { _ in
            countOfExecutions += 1
            
            return true
        }
        
        let result: ThreeWaysTrie<Int> = sut.filter(isIncluded)
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testFilter_whenIsNotEmpty_thenIsIncludedExecutesOnEveryTrieElementAndReturnsTrieWithElementsFiltered() {
        whenIsNotEmpty()
        var capturedElements: Array<SutElement> = []
        let isIncluded: (SutElement) -> Bool = {
            capturedElements.append($0)
            
            return $0.key.hasPrefix("s")
        }
        let expectedResult: Dictionary<String, Int> = Dictionary(uniqueKeysWithValues: sut!.map({ $0 }))
            .filter(isIncluded)
        capturedElements = []
        
        let result: ThreeWaysTrie<Int> = sut.filter(isIncluded)
        XCTAssertTrue(capturedElements.elementsEqual(sut, by: { $0.key == $1.key && $0.value == $1.value }))
        XCTAssertEqual(result.count, expectedResult.count)
        result.forEach({ XCTAssertEqual($0.value, expectedResult[$0.key]) })
    }
    
    func testFilter_COW() {
        whenIsNotEmpty()
        let predicate = { (element: SutElement) -> Bool in
            element.key.hasPrefix("s")
        }
        let result: ThreeWaysTrie = sut.filter(predicate)
        XCTAssertFalse(sut.root === result.root)
        XCTAssertFalse(sut.allSatisfy(predicate))
        XCTAssertTrue(result.allSatisfy(predicate))
    }
    
    func testFilter_whenIsIncludedThrows_thenRethrows() {
        whenIsNotEmpty()
        whenIsNotEmpty()
        do {
            let _: ThreeWaysTrie<Int> = try sut.filter({ _ in throw someError })
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - merge(_:uniquingKeysWith:) tests
    func testMergeOther_whenIsEmptyThenSetsRootToOtherRootAndCombineNeverExecutes() throws {
        try XCTSkipIf(!sut.isEmpty, "Trie must be empty for this test")
        var countOfExecutions = 0
        let combine = { (previous: Int, latest: Int) -> Int in
            countOfExecutions += 1
            
            return latest
        }
        let other = ThreeWaysTrie(uniqueKeysWithValues: givenKeys().enumerated().map({ ($0.element, $0.offset) }))
        
        sut.merge(other, uniquingKeysWith: combine)
        XCTAssertTrue(sut.root === other.root)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testMergeSequence_whenIsEmptyAndSequenceIsEmpty_thenCombineNeverExecutesAndRootStaysNil() throws {
        try XCTSkipIf(!sut.isEmpty, "Trie must be empty for this test")
        var countOfExecutions = 0
        let combine = { (previous: Int, latest: Int) -> Int in
            countOfExecutions += 1
            
            return latest
        }
        var seq = TestingSequence<(String, Int)>([])
        
        sut.merge(seq, uniquingKeysWith: combine)
        XCTAssertNil(sut.root)
        XCTAssertEqual(countOfExecutions, 0)
        
        sut = ThreeWaysTrie()
        seq.hasContiguousStorage = false
        countOfExecutions = 0
        
        sut.merge(seq, uniquingKeysWith: combine)
        XCTAssertNil(sut.root)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testMergeOther_whenOtherIsEmpty_thenCombineNeverExecutesAndRootStaysTheSame() throws {
        try XCTSkipIf(!sut.isEmpty, "Trie must be empty at first for this test")
        let other = ThreeWaysTrie<Int>()
        var countOfExecutions = 0
        let combine = { (previous: Int, latest: Int) -> Int in
            countOfExecutions += 1
            
            return latest
        }
        var prevElements = sut!.map { $0 }
        weak var prevRoot = sut.root
        
        sut.merge(other, uniquingKeysWith: combine)
        XCTAssertTrue(sut.root === prevRoot)
        XCTAssertEqual(countOfExecutions, 0)
        XCTAssertTrue(prevElements.elementsEqual(sut, by: { $0.key == $1.key && $0.value == $1.value }))
        
        whenIsNotEmpty()
        prevElements = sut!.map { $0 }
        prevRoot = sut.root
        countOfExecutions = 0
        
        sut.merge(other, uniquingKeysWith: combine)
        XCTAssertTrue(sut.root === prevRoot)
        XCTAssertEqual(countOfExecutions, 0)
        XCTAssertTrue(prevElements.elementsEqual(sut, by: { $0.key == $1.key && $0.value == $1.value }))
    }
    
    func testMergeSequence_whenSequenceIsEmpty_thenCombineNeverExecutesAndRootStaysTheSame() throws {
        try XCTSkipIf(!sut.isEmpty, "Trie must be empty at first for this test")
        var seq = TestingSequence<(String, Int)>([])
        var countOfExecutions = 0
        let combine = { (previous: Int, latest: Int) -> Int in
            countOfExecutions += 1
            
            return latest
        }
        var prevElements = sut!.map { $0 }
        weak var prevRoot = sut.root
        
        sut.merge(seq, uniquingKeysWith: combine)
        XCTAssertTrue(sut.root === prevRoot)
        XCTAssertEqual(countOfExecutions, 0)
        XCTAssertTrue(prevElements.elementsEqual(sut, by: { $0.key == $1.key && $0.value == $1.value }))
        
        whenIsNotEmpty()
        prevElements = sut!.map { $0 }
        prevRoot = sut.root
        countOfExecutions = 0
        
        sut.merge(seq, uniquingKeysWith: combine)
        XCTAssertTrue(sut.root === prevRoot)
        XCTAssertEqual(countOfExecutions, 0)
        XCTAssertTrue(prevElements.elementsEqual(sut, by: { $0.key == $1.key && $0.value == $1.value }))
        
        // repeat tests with sequence having contiguous buffer unavailable:
        seq.hasContiguousStorage = false
        
        sut = ThreeWaysTrie()
        prevElements = sut!.map { $0 }
        prevRoot = sut.root
        countOfExecutions = 0
        sut.merge(seq, uniquingKeysWith: combine)
        XCTAssertTrue(sut.root === prevRoot)
        XCTAssertEqual(countOfExecutions, 0)
        XCTAssertTrue(prevElements.elementsEqual(sut, by: { $0.key == $1.key && $0.value == $1.value }))
        
        whenIsNotEmpty()
        prevElements = sut!.map { $0 }
        prevRoot = sut.root
        countOfExecutions = 0
        
        sut.merge(seq, uniquingKeysWith: combine)
        XCTAssertTrue(sut.root === prevRoot)
        XCTAssertEqual(countOfExecutions, 0)
        XCTAssertTrue(prevElements.elementsEqual(sut, by: { $0.key == $1.key && $0.value == $1.value }))
    }
    
    func testMergeOther_whenIsNotEmptyAndOtherIsNotEmpty_thenCombineExecutesForElementsWithSameKeyAndMergesOtherElementsIntoIntoTrie() {
        whenIsNotEmpty()
        let clone = sut!
        var countOfExecutions = 0
        let combine = { (previous: Int, latest: Int) -> Int in
            countOfExecutions += 1
            
            return previous + latest
        }
        let other = ThreeWaysTrie<Int>(
            uniqueKeysWithValues: givenKeys()
                .shuffled()
                .dropLast(Int.random(in: 1...3))
                .enumerated()
                .map({ ($0.element, $0.offset + Int.random(in: 10...20)) })
        )
        let expectedResult = Dictionary<String, Int>(
            uniqueKeysWithValues: sut!
                .map({ $0 })
        )
        .merging(other.map({ $0 }), uniquingKeysWith: combine)
        countOfExecutions = 0
        
        sut.merge(other, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, other.count)
        XCTAssertEqual(sut.count, expectedResult.count)
        for (key, value) in sut {
            XCTAssertEqual(value, expectedResult[key])
        }
        // Copy On Write check:
        XCTAssertFalse(sut.root === clone.root)
    }
    
    func testMergeSequence_whenBothArentEmptyAndHaveElementsWithSameKey_thenCombineExecutesForSuchElementsAndElementsAreMergedInTrie() {
        whenIsNotEmpty()
        var countOfExecutions = 0
        let combine = { (previous: Int, latest: Int) -> Int in
            countOfExecutions += 1
            
            return previous + latest
        }
        var seq = TestingSequence<(String, Int)>(
            givenKeys()
                .shuffled()
                .dropLast(Int.random(in: 1...3))
                .enumerated()
                .map({ ($0.element, $0.offset + Int.random(in: 10...20)) })
        )
        let expectedResult = Dictionary<String, Int>(
            uniqueKeysWithValues: sut!
                .map({ $0 })
        )
        .merging(seq, uniquingKeysWith: combine)
        countOfExecutions = 0
        var clone = sut!
        
        sut.merge(seq, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, seq.underestimatedCount)
        XCTAssertEqual(sut.count, expectedResult.count)
        for (key, value) in sut {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(sut.root === clone.root)
        
        // repeat test with sequence having contiguous buffer unavailable:
        seq.hasContiguousStorage = false
        whenIsNotEmpty()
        countOfExecutions = 0
        clone = sut!
        
        sut.merge(seq, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, seq.underestimatedCount)
        XCTAssertEqual(sut.count, expectedResult.count)
        for (key, value) in sut {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(sut.root === clone.root)
    }
    
    func testMergeOther_whenBothArentEmptyAndHaveNoKeysInCommon_thenCombineNeverExecutesAndAddsOtherElementsInTrie() {
        whenIsNotEmpty()
        let clone = sut!
        let other: ThreeWaysTrie<Int> = [
            "for" : 6,
            "a" : 7,
            "very" : 8,
            "good" : 9,
            "price" : 10
        ]
        var countOfExecutions = 0
        let combine = { (previous: Int, latest: Int) -> Int in
            countOfExecutions += 1
            
            return previous + latest
        }
        let expectedResult = Dictionary<String, Int>(
            uniqueKeysWithValues: sut!
                .map({ $0 })
        )
        .merging(other.map({ $0 }), uniquingKeysWith: combine)
        countOfExecutions = 0
        
        sut.merge(other, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, 0)
        XCTAssertEqual(sut.count, expectedResult.count)
        for (key, value) in sut {
            XCTAssertEqual(value, expectedResult[key])
        }
        // Copy On Write check:
        XCTAssertFalse(sut.root === clone.root)
    }
    
    func testMergeSequence_whenBothArentEmptyAndNoDuplicateKeysInSequenceAndBothHaveNoKeysInCommon_thenCombineNeverExecutesAndAddsElementsFromSequenceToTrie() {
        whenIsNotEmpty()
        var seq  = TestingSequence([
            ("for" , 6),
            ("a", 7),
            ("very", 8),
            ("good", 9),
            ("price", 10)
        ])
        var countOfExecutions = 0
        let combine = { (previous: Int, latest: Int) -> Int in
            countOfExecutions += 1
            
            return previous + latest
        }
        let expectedResult = Dictionary<String, Int>(
            uniqueKeysWithValues: sut!
                .map({ $0 })
        )
        .merging(seq, uniquingKeysWith: combine)
        countOfExecutions = 0
        var clone = sut!
        
        sut.merge(seq, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, 0)
        XCTAssertEqual(sut.count, expectedResult.count)
        for (key, value) in sut {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(sut.root === clone.root)
        
        // repeat test with sequence having contiguous buffer unavailable:
        seq.hasContiguousStorage = false
        sut.removeAll()
        whenIsNotEmpty()
        countOfExecutions = 0
        clone = sut!
        
        sut.merge(seq, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, 0)
        XCTAssertEqual(sut.count, expectedResult.count)
        for (key, value) in sut {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(sut.root === clone.root)
    }
    
    func testMergeSequence_whenSequenceIsNotEmptyAndContainsDuplicateKeysButNoKeysInCommonWihtTrie_thenCombineExecutesOnThoseElementsAndAddsMergedElementsFromSequenceToTrie() {
        var countOfExecutions = 0
        let combine = { (previous: Int, latest: Int) -> Int in
            countOfExecutions += 1
            
            return previous + latest
        }
        
        // Trie is empty:
        sut = ThreeWaysTrie()
        let expectedCountOfExectutions = Int.random(in: 1...5)
        let base = [
            ("for" , 6),
            ("a", 7),
            ("very", 8),
            ("good", 9),
            ("price", 10)
        ]
        let duplicates = Array(base.shuffled().prefix(upTo: expectedCountOfExectutions))
        var seq = TestingSequence<(String, Int)>(
            (base + duplicates).shuffled()
        )
        var expectedResult = Dictionary<String, Int>(
            uniqueKeysWithValues: sut!.map({ $0 })
        )
        .merging(seq, uniquingKeysWith: combine)
        countOfExecutions = 0
        var clone = sut!
        
        sut.merge(seq, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, expectedCountOfExectutions)
        XCTAssertEqual(sut.count, expectedResult.count)
        for (key, value) in sut {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(sut.root === clone.root)
        
        // repeat test with sequence having contiguous buffer unavailable:
        seq.hasContiguousStorage = false
        countOfExecutions = 0
        sut = ThreeWaysTrie()
        clone = sut!
        
        sut.merge(seq, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, expectedCountOfExectutions)
        XCTAssertEqual(sut.count, expectedResult.count)
        for (key, value) in sut {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(sut.root === clone.root)
        
        // Trie is not empty:
        sut.removeAll()
        whenIsNotEmpty()
        seq.hasContiguousStorage = true
        expectedResult = Dictionary<String, Int>(
            uniqueKeysWithValues: sut!.map({ $0 })
        )
        .merging(seq, uniquingKeysWith: combine)
        countOfExecutions = 0
        clone = sut!
        
        sut.merge(seq, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, expectedCountOfExectutions)
        XCTAssertEqual(sut.count, expectedResult.count)
        for (key, value) in sut {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(sut.root === clone.root)
        
        // repeat test with sequence having contiguous buffer unavailable:
        seq.hasContiguousStorage = false
        countOfExecutions = 0
        sut.removeAll()
        whenIsNotEmpty()
        clone = sut!
        
        sut.merge(seq, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, expectedCountOfExectutions)
        XCTAssertEqual(sut.count, expectedResult.count)
        for (key, value) in sut {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(sut.root === clone.root)
    }
    
    func testMerge_whenCombineThrows_thenRethrows() {
        whenIsNotEmpty()
        let combine = { (p: Int, l: Int) throws -> Int in throw someError }
        let other = sut!
        // when other is another Trie:
        do {
            try sut.merge(other, uniquingKeysWith: combine)
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
        
        // when other is a sequence:
        var seq = TestingSequence<(String, Int)>(other.map({ $0 }))
        do {
            try sut.merge(seq, uniquingKeysWith: combine)
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
        
        seq.hasContiguousStorage = false
        do {
            try sut.merge(seq, uniquingKeysWith: combine)
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - merging(_:uniquingKeysWith:) tests
    func testMergingOther_whenIsEmptyThenReturnsOtherAndCombineNeverExecutes() throws {
        try XCTSkipIf(!sut.isEmpty, "Trie must be empty for this test")
        var countOfExecutions = 0
        let combine = { (previous: Int, latest: Int) -> Int in
            countOfExecutions += 1
            
            return latest
        }
        let other = ThreeWaysTrie(uniqueKeysWithValues: givenKeys().enumerated().map({ ($0.element, $0.offset) }))
        
        let result = sut.merging(other, uniquingKeysWith: combine)
        XCTAssertEqual(result, other)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testMergingSequence_whenIsEmptyAndSequenceIsEmpty_thenCombineNeverExecutesAndReturnsEmptyTrie() throws {
        try XCTSkipIf(!sut.isEmpty, "Trie must be empty for this test")
        var countOfExecutions = 0
        let combine = { (previous: Int, latest: Int) -> Int in
            countOfExecutions += 1
            
            return latest
        }
        var seq = TestingSequence<(String, Int)>([])
        
        var result = sut.merging(seq, uniquingKeysWith: combine)
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(countOfExecutions, 0)
        
        seq.hasContiguousStorage = false
        countOfExecutions = 0
        
        result = sut.merging(seq, uniquingKeysWith: combine)
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testMergingOther_whenOtherIsEmpty_thenCombineNeverExecutesAndReturnsTrie() throws {
        try XCTSkipIf(!sut.isEmpty, "Trie must be empty at first for this test")
        let other = ThreeWaysTrie<Int>()
        var countOfExecutions = 0
        let combine = { (previous: Int, latest: Int) -> Int in
            countOfExecutions += 1
            
            return latest
        }
        
        var result = sut.merging(other, uniquingKeysWith: combine)
        XCTAssertEqual(result, sut)
        XCTAssertEqual(countOfExecutions, 0)
                
        whenIsNotEmpty()
        countOfExecutions = 0
        
        result = sut.merging(other, uniquingKeysWith: combine)
        XCTAssertEqual(result, sut)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testMergingSequence_whenSequenceIsEmpty_thenCombineNeverExecutesAndReturnsTrie() throws {
        try XCTSkipIf(!sut.isEmpty, "Trie must be empty at first for this test")
        var seq = TestingSequence<(String, Int)>([])
        var countOfExecutions = 0
        let combine = { (previous: Int, latest: Int) -> Int in
            countOfExecutions += 1
            
            return latest
        }
        
        var result = sut.merging(seq, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, 0)
        XCTAssertNil(result.root)
        
        whenIsNotEmpty()
        var prevElements = sut!.map { $0 }
        countOfExecutions = 0
        
        result = sut.merging(seq, uniquingKeysWith: combine)
        XCTAssertTrue(result.root === sut.root)
        XCTAssertEqual(countOfExecutions, 0)
        XCTAssertTrue(prevElements.elementsEqual(result, by: { $0.key == $1.key && $0.value == $1.value }))
        
        // repeat tests with sequence having contiguous buffer unavailable:
        seq.hasContiguousStorage = false
        
        sut = ThreeWaysTrie()
        prevElements = sut!.map { $0 }
        countOfExecutions = 0
        result = sut.merging(seq, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, 0)
        XCTAssertNil(result.root)
        
        whenIsNotEmpty()
        prevElements = sut!.map { $0 }
        countOfExecutions = 0
        
        result = sut.merging(seq, uniquingKeysWith: combine)
        XCTAssertTrue(result.root === sut.root)
        XCTAssertEqual(countOfExecutions, 0)
        XCTAssertTrue(prevElements.elementsEqual(result, by: { $0.key == $1.key && $0.value == $1.value }))
    }
    
    func testMergingOther_whenIsNotEmptyAndOtherIsNotEmpty_thenCombineExecutesForElementsWithCommonKeyAndReturnsTrieWithMergedElements() {
        whenIsNotEmpty()
        var countOfExecutions = 0
        let combine = { (previous: Int, latest: Int) -> Int in
            countOfExecutions += 1
            
            return previous + latest
        }
        var other = ThreeWaysTrie<Int>(
            uniqueKeysWithValues: givenKeys()
                .shuffled()
                .dropLast(Int.random(in: 1...3))
                .enumerated()
                .map({ ($0.element, $0.offset + Int.random(in: 10...20)) })
        )
        let expectedResult = Dictionary<String, Int>(
            uniqueKeysWithValues: sut!
                .map({ $0 })
        )
        .merging(other.map({ $0 }), uniquingKeysWith: combine)
        countOfExecutions = 0
        
        var result = sut.merging(other, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, min(sut.count, other.count))
        XCTAssertEqual(result.count, expectedResult.count)
        for (key, value) in result {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(result.root === sut.root)
        XCTAssertFalse(result.root === other.root)
        
        // Let's also swap other with sut for one more test
        whenIsNotEmpty()
        (sut, other) = (other, sut)
        countOfExecutions = 0
        
        result = sut.merging(other, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, min(sut.count, other.count))
        XCTAssertEqual(result.count, expectedResult.count)
        for (key, value) in result {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(result.root === sut.root)
        XCTAssertFalse(result.root === other.root)
    }
    
    func testMergingSequence_whenBothArentEmptyAndHaveElementsWithSameKey_thenCombineExecutesForSuchElementsAndReturnsTrieWithElementsMergedFromBoth() {
        whenIsNotEmpty()
        var countOfExecutions = 0
        let combine = { (previous: Int, latest: Int) -> Int in
            countOfExecutions += 1
            
            return previous + latest
        }
        var seq = TestingSequence<(String, Int)>(
            givenKeys()
                .shuffled()
                .dropLast(Int.random(in: 1...3))
                .enumerated()
                .map({ ($0.element, $0.offset + Int.random(in: 10...20)) })
        )
        let expectedResult = Dictionary<String, Int>(
            uniqueKeysWithValues: sut!
                .map({ $0 })
        )
        .merging(seq, uniquingKeysWith: combine)
        countOfExecutions = 0
        
        var result = sut.merging(seq, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, seq.underestimatedCount)
        XCTAssertEqual(result.count, expectedResult.count)
        for (key, value) in result {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(result.root === sut.root)
        
        // repeat test with sequence having contiguous buffer unavailable:
        seq.hasContiguousStorage = false
        whenIsNotEmpty()
        countOfExecutions = 0
        
        result = sut.merging(seq, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, seq.underestimatedCount)
        XCTAssertEqual(result.count, expectedResult.count)
        for (key, value) in result {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(result.root === sut.root)
    }
    
    func testMergingOther_whenBothArentEmptyAndHaveNoCommonKeys_thenCombineNeverExecutesAndReturnsTrieWithElementsFromBothTrie() {
        whenIsNotEmpty()
        var other: ThreeWaysTrie<Int> = [
            "for" : 6,
            "a" : 7,
            "very" : 8,
            "good" : 9,
            "price" : 10
        ]
        var countOfExecutions = 0
        let combine = { (previous: Int, latest: Int) -> Int in
            countOfExecutions += 1
            
            return previous + latest
        }
        let expectedResult = Dictionary<String, Int>(
            uniqueKeysWithValues: sut!
                .map({ $0 })
        )
        .merging(other.map({ $0 }), uniquingKeysWith: combine)
        countOfExecutions = 0
        
        var result = sut.merging(other, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, 0)
        XCTAssertEqual(result.count, expectedResult.count)
        for (key, value) in result {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(result.root === sut.root)
        XCTAssertFalse(result.root === other.root)
        
        // Let's also swap other with sut for one more test
        whenIsNotEmpty()
        (sut, other) = (other, sut)
        countOfExecutions = 0
        
        result = sut.merging(other, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, 0)
        XCTAssertEqual(result.count, expectedResult.count)
        for (key, value) in result {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(result.root === sut.root)
        XCTAssertFalse(result.root === other.root)
    }
    
    func testMergingSequence_whenBothArentEmptyAndNoDuplicateKeysInSequenceAndBothHaveNoKeysInCommon_thenCombineNeverExecutesAndReturnsTrieWithElementsFromBoth() {
        whenIsNotEmpty()
        var seq  = TestingSequence([
            ("for" , 6),
            ("a", 7),
            ("very", 8),
            ("good", 9),
            ("price", 10)
        ])
        var countOfExecutions = 0
        let combine = { (previous: Int, latest: Int) -> Int in
            countOfExecutions += 1
            
            return previous + latest
        }
        let expectedResult = Dictionary<String, Int>(
            uniqueKeysWithValues: sut!
                .map({ $0 })
        )
        .merging(seq, uniquingKeysWith: combine)
        countOfExecutions = 0
        
        var result = sut.merging(seq, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, 0)
        XCTAssertEqual(result.count, expectedResult.count)
        for (key, value) in result {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(sut.root === result.root)
        
        // repeat test with sequence having contiguous buffer unavailable:
        seq.hasContiguousStorage = false
        whenIsNotEmpty()
        countOfExecutions = 0
        
        result = sut.merging(seq, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, 0)
        XCTAssertEqual(result.count, expectedResult.count)
        for (key, value) in result {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(sut.root === result.root)
    }
    
    func testMergingSequence_whenSequenceIsNotEmptyAndContainsDuplicateKeysButNoKeysInCommonWihtTrie_thenCombineExecutesOnThoseElementsAndReturnsTrieWithMergedElements() {
        var countOfExecutions = 0
        let combine = { (previous: Int, latest: Int) -> Int in
            countOfExecutions += 1
            
            return previous + latest
        }
        
        // Trie is empty:
        sut = ThreeWaysTrie()
        let expectedCountOfExectutions = Int.random(in: 1...5)
        let base = [
            ("for" , 6),
            ("a", 7),
            ("very", 8),
            ("good", 9),
            ("price", 10)
        ]
        let duplicates = Array(base.shuffled().prefix(upTo: expectedCountOfExectutions))
        var seq = TestingSequence<(String, Int)>(
            (base + duplicates).shuffled()
        )
        var expectedResult = Dictionary<String, Int>(
            uniqueKeysWithValues: sut!.map({ $0 })
        )
        .merging(seq, uniquingKeysWith: combine)
        countOfExecutions = 0
        
        var result = sut.merging(seq, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, expectedCountOfExectutions)
        XCTAssertEqual(result.count, expectedResult.count)
        for (key, value) in result {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(sut.root === result.root)
        
        // repeat test with sequence having contiguous buffer unavailable:
        seq.hasContiguousStorage = false
        countOfExecutions = 0
        
        result = sut.merging(seq, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, expectedCountOfExectutions)
        XCTAssertEqual(result.count, expectedResult.count)
        for (key, value) in result {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(sut.root === result.root)
        
        // Trie is not empty:
        whenIsNotEmpty()
        seq.hasContiguousStorage = true
        expectedResult = Dictionary<String, Int>(
            uniqueKeysWithValues: sut!.map({ $0 })
        )
        .merging(seq, uniquingKeysWith: combine)
        countOfExecutions = 0
        
        result = sut.merging(seq, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, expectedCountOfExectutions)
        XCTAssertEqual(result.count, expectedResult.count)
        for (key, value) in result {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(sut.root === result.root)
        
        // repeat test with sequence having contiguous buffer unavailable:
        seq.hasContiguousStorage = false
        countOfExecutions = 0
        
        result = sut.merging(seq, uniquingKeysWith: combine)
        XCTAssertEqual(countOfExecutions, expectedCountOfExectutions)
        XCTAssertEqual(result.count, expectedResult.count)
        for (key, value) in result {
            XCTAssertEqual(value, expectedResult[key])
        }
        XCTAssertFalse(sut.root === result.root)
    }
    
    func testMerging_whenCombineThrows_thenRethrows() {
        whenIsNotEmpty()
        let combine = { (p: Int, l: Int) throws -> Int in throw someError }
        let other = sut!
        // when other is another Trie:
        do {
            let _ = try sut.merging(other, uniquingKeysWith: combine)
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
        
        // when other is a sequence:
        var seq = TestingSequence<(String, Int)>(other.map({ $0 }))
        do {
            let _ = try sut.merging(seq, uniquingKeysWith: combine)
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
        
        seq.hasContiguousStorage = false
        do {
            let _ = try sut.merging(seq, uniquingKeysWith: combine)
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
}
