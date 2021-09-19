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
        whenIsNotEmpty()
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
        XCTFail("Not yet implementd")
    }
    
}
