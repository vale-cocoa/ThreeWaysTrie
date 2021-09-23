//
//  ThreeWaysTrieSequenceTests.swift
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

final class ThreeWaysTrieSequenceTests: BaseTrieTestClass {
    typealias SutElement = ThreeWaysTrie<Int>.Element
    
    func testUnderstimatedCount_returnsSameValueOfCount() {
        XCTAssertEqual(sut.underestimatedCount, sut.count)
        for (value, key) in givenKeys().enumerated() {
            sut.root = sut._put(node: sut.root, key: key, value: value, index: key.startIndex, uniquingKeysWith: { $1 })
            XCTAssertEqual(sut.underestimatedCount, sut.count)
        }
    }
    
    func testMakeIterator() {
        var iter = sut.makeIterator()
        XCTAssertNotNil(iter)
        
        whenIsNotEmpty()
        iter = sut.makeIterator()
        XCTAssertNotNil(iter)
    }
    
    func testIteratorNext_whenIsEmpty_thenReturnsNil() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        
        var iter = sut.makeIterator()
        XCTAssertNil(iter.next())
    }
    
    func testIteratorNext_whenIsNotEmpty_thenReturnsElementsInTriesRankOrder() {
        whenIsNotEmpty()
        let expectedResult = givenKeys()
            .enumerated()
            .map({ (key: $0.element, value: $0.offset) })
            .sorted(by: { $0.key < $1.key })
        var rank = 0
        var iter = sut.makeIterator()
        
        while let (key, value) = iter.next() {
            let (expectedKey, expectedValue) = expectedResult[rank]
            XCTAssertEqual(key, expectedKey)
            XCTAssertEqual(value, expectedValue)
            rank += 1
        }
        XCTAssertEqual(rank, sut.count, "Hasn't iterated over all elements")
    }
    
    // MARK: - FP methods tests
    // MARK: - allSatisfy(_:) tests
    func testAllSatisfy_whenIsEmpty_thenPredicateNeverExecutesAndReturnsTrue() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        var countOfExecutions = 0
        let predicate: (SutElement) -> Bool = { _ in
            countOfExecutions += 1
            
            return false
        }
        
        XCTAssertTrue(sut.allSatisfy(predicate))
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testAllSatisfy_whenIsNotEmptyAndPredicateReturnsTrueForEveryElementInTrie_thenPredicateExecutesForEveryElementInTrieAndReturnsTrue() {
        whenIsNotEmpty()
        var capturedElements: Array<SutElement> = []
        let predicate: (SutElement) -> Bool = {
            capturedElements.append($0)
            
            return true
        }
        
        XCTAssertTrue(sut.allSatisfy(predicate))
        XCTAssertEqual(capturedElements.count, sut.count)
        for (key, value) in capturedElements {
            let expectedValue = sut._get(node: sut.root, key: key, index: key.startIndex)?.value
            XCTAssertEqual(value, expectedValue)
        }
        do {
            let _ = try Dictionary<String, Int>(capturedElements) { _, _ in
                throw someError
            }
        } catch {
            XCTFail("Has executed predicate more than once on an element")
        }
    }
    
    func testAllSatisfy_whenIsNotEmptyAndPredicateReturnsFalseForOneElement_thenReturnsFalse() {
        whenIsNotEmpty()
        var countOfExecutions = 0
        let valueNotSatisfying = Int.random(in: 0..<sut.count)
        let predicate: (SutElement) -> Bool = {
            countOfExecutions += 1
            
            return $0.value != valueNotSatisfying
        }
        
        XCTAssertFalse(sut.allSatisfy(predicate))
        // Might stop executing predicate before all elements in Trie are tested:
        XCTAssertLessThanOrEqual(countOfExecutions, sut.count)
    }
    
    func testAllSatisfy_whenPredicateThrows_thenRethrows() {
        whenIsNotEmpty()
        do {
            let _ = try sut.allSatisfy { _ in throw someError }
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - contains(where:) tests
    func testContains_whenIsEmpty_thenPredicateNeverExecutesAndReturnsFalse() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        var countOfExecutions = 0
        let predicate: (SutElement) -> Bool = { _ in
            countOfExecutions += 1
            
            return true
        }
        
        XCTAssertFalse(sut.contains(where: predicate))
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testContains_whenIsNotEmptyAndPredicateAlwaysReturnsFalse_thenPredicateExecutesOnEveryTrieElementAndReturnsFalse() {
        whenIsNotEmpty()
        var capturedElements: Array<SutElement> = []
        let predicate: (SutElement) -> Bool = {
            capturedElements.append($0)
            
            return false
        }
        
        XCTAssertFalse(sut.contains(where: predicate))
        XCTAssertEqual(capturedElements.count, sut.count)
        for (key, value) in capturedElements {
            let expectedValue = sut._get(node: sut.root, key: key, index: key.startIndex)?.value
            XCTAssertEqual(value, expectedValue)
        }
        do {
            let _ = try Dictionary<String, Int>(capturedElements) { _, _ in
                throw someError
            }
        } catch {
            XCTFail("Has executed predicate more than once on an element")
        }
    }
    
    func testContains_whenPredicateReturnsTrueForAnElement_thenReturnsTrue() {
        whenIsNotEmpty()
        var countOfExecutions = 0
        let keyToFind = givenKeys().randomElement()!
        let predicate: (SutElement) -> Bool = {
            countOfExecutions += 1
            
            return $0.key == keyToFind
        }
        
        XCTAssertTrue(sut.contains(where: predicate))
        // Might stop executing predicate before all elements in Trie are tested:
        XCTAssertLessThanOrEqual(countOfExecutions, sut.count)
    }
    
    func testContains_whenPredicateThrows_thenRethrows() {
        whenIsNotEmpty()
        do {
            let _ = try sut.contains { _ in throw someError }
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - first(where:) tests
    func testFirst_whenIsEmpty_thenPredicateNeverExecutesAndReturnsNil() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        var countOfExecutions = 0
        let predicate: (SutElement) -> Bool = { _ in
            countOfExecutions += 1
            
            return false
        }
        
        XCTAssertNil(sut.first(where: predicate))
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testFirst_whenIsNotEmptyAndPredicateAlwaysReturnsFalse_thenPredciateExecutesOnEveryElementAndReturnsNil() {
        whenIsNotEmpty()
        var capturedElements: Array<SutElement> = []
        let predicate: (SutElement) -> Bool = {
            capturedElements.append($0)
            
            return false
        }
        XCTAssertNil(sut.first(where: predicate))
        XCTAssertEqual(capturedElements.count, sut.count)
        for (key, value) in capturedElements {
            let expectedValue = sut._get(node: sut.root, key: key, index: key.startIndex)?.value
            XCTAssertEqual(value, expectedValue)
        }
        do {
            let _ = try Dictionary<String, Int>(capturedElements) { _, _ in
                throw someError
            }
        } catch {
            XCTFail("Has executed predicate more than once on an element")
        }
    }
    
    func testFirst_whenIsNotEmptyAndPredicateReturnsTrueForSomeElements_thenReturnsFirstTrieElementThatTestedTrueInRankOrder() {
        whenIsNotEmpty()
        let sortedElements = givenKeys()
            .enumerated()
            .map({ (key: $0.element, value: $0.offset) })
            .sorted(by: { $0.key < $1.key })
        var countOfExecutions = 0
        let predicate: (SutElement) -> Bool = {
            countOfExecutions += 1
            
            return $0.value % 2 == 1
        }
        let expectedResult = sortedElements.first(where: predicate)!
        countOfExecutions = 0
        
        let result = sut.first(where: predicate)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.key, expectedResult.key)
        XCTAssertEqual(result?.value, expectedResult.value)
        // Might stop executing predicate before all elements in Trie are tested:
        XCTAssertLessThanOrEqual(countOfExecutions, sut.count)
    }
    
    func testFirst_whenPredicateThrows_thenRethrows() {
        whenIsNotEmpty()
        do {
            let _ = try sut.first { _ in throw someError }
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - last(where:) tests
    func testLast_whenIsEmpty_thenPredciateNeverExecutesAndReturnsNil() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        var countOfExecutions = 0
        let predicate: (SutElement) -> Bool = { _ in
            countOfExecutions += 1
            
            return false
        }
        
        XCTAssertNil(sut.last(where: predicate))
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testLast_whenIsNotEmptyAndPredicateAlwaysReturnsFalse_thenPredciateExecutesOnEveryElementAndReturnsNil() {
        whenIsNotEmpty()
        var capturedElements: Array<SutElement> = []
        let predicate: (SutElement) -> Bool = {
            capturedElements.append($0)
            
            return false
        }
        XCTAssertNil(sut.last(where: predicate))
        XCTAssertEqual(capturedElements.count, sut.count)
        for (key, value) in capturedElements {
            let expectedValue = sut._get(node: sut.root, key: key, index: key.startIndex)?.value
            XCTAssertEqual(value, expectedValue)
        }
        do {
            let _ = try Dictionary<String, Int>(capturedElements) { _, _ in
                throw someError
            }
        } catch {
            XCTFail("Has executed predicate more than once on an element")
        }
    }
    
    func testLast_whenIsNotEmptyAndPredicateReturnsTrueForSomeElements_thenReturnsFirstTrieElementThatTestedTrueInRankOrder() {
        whenIsNotEmpty()
        let sortedElements = givenKeys()
            .enumerated()
            .map({ (key: $0.element, value: $0.offset) })
            .sorted(by: { $0.key < $1.key })
        var countOfExecutions = 0
        let predicate: (SutElement) -> Bool = {
            countOfExecutions += 1
            
            return $0.value % 2 == 1
        }
        let expectedResult = sortedElements.last(where: predicate)!
        countOfExecutions = 0
        
        let result = sut.last(where: predicate)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.key, expectedResult.key)
        XCTAssertEqual(result?.value, expectedResult.value)
        // Might stop executing predicate before all elements in Trie are tested:
        XCTAssertLessThanOrEqual(countOfExecutions, sut.count)
    }
    
    func testLast_whenPredicateThrows_thenRethrows() {
        whenIsNotEmpty()
        do {
            let _ = try sut.last { _ in throw someError }
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - forEach(_:) tests
    func testForEach_whenIsEmpty_thenBodyNeverExecutes() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        var countOfExecutions = 0
        let body: (SutElement) -> Void = { _ in
            countOfExecutions += 1
        }
        sut.forEach(body)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testForEach_whenIsNotEmpty_thenBodyExecutesOnEveryElementOfTrieInRankOrder() {
        whenIsNotEmpty()
        var caputeredElements: Array<SutElement> = []
        let body: (SutElement) -> Void = {
            caputeredElements.append($0)
        }
        let expectedResult = givenKeys()
            .enumerated()
            .map({ (key: $0.element, value: $0.offset) })
            .sorted(by: { $0.key < $1.key })
        
        sut.forEach(body)
        XCTAssertTrue(caputeredElements.elementsEqual(expectedResult, by: { $0.key == $1.key && $0.value == $1.value }))
    }
    
    func testForEach_whenBodythrows_thenRethrows() {
        whenIsNotEmpty()
        do {
            try sut.forEach { _ in throw someError }
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - map(_:) tests
    func testMap_whenIsEmpty_thenTransformNeverExecutesAndReturnsEmptyArray() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        var countOfExecutions = 0
        let transform: (SutElement) -> Double = {
            countOfExecutions += 1
            
            return Double($0.value)
        }
        
        let mapped = sut.map(transform)
        XCTAssertTrue(mapped.isEmpty)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testMap_whenIsNotEmpty_thenTransformExecutesOnEveryElementOfTrieInRankOrderAndReturnsArrayWithTrieElementsTransformed() {
        whenIsNotEmpty()
        let sortedElements = givenKeys()
            .enumerated()
            .map({ (key: $0.element, value: $0.offset) })
            .sorted(by: { $0.key < $1.key })
        let transform: (SutElement) -> Double = {
            Double($0.value)
        }
        let expectedResult = sortedElements.map(transform)
        let result = sut.map(transform)
        XCTAssertEqual(result, expectedResult)
    }
    
    func testMap_whenTransformThrows_thenRethrows() {
        whenIsNotEmpty()
        do {
            let _ = try sut.map { _ in throw someError }
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - compactMap(_:) tests
    func testCompactMap_whenIsEmpty_thenTransformNeverExecutesAndReturnsEmptyArray() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        var countOfExecutions = 0
        let transform: (SutElement) -> Double? = {
            countOfExecutions += 1
            
            return Double($0.value)
        }
        
        let mapped = sut.compactMap(transform)
        XCTAssertTrue(mapped.isEmpty)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testCompactMap_whenIsnotEmptyAndTransformReturnsNilForEveryElementInTrie_thenReturnsEmptyArray() {
        whenIsNotEmpty()
        var capturedElements: Array<SutElement> = []
        let transform: (SutElement) -> Double? = {
            capturedElements.append($0)
            
            return nil
        }
        let expectedResult = givenKeys()
            .enumerated()
            .map({ (key: $0.element, value: $0.offset) })
            .sorted(by: { $0.key < $1.key })
        
        let result = sut.compactMap(transform)
        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(capturedElements.elementsEqual(expectedResult) { $0.key == $1.key && $0.value == $1.value })
    }
    
    func testCompactMap_whenIsnotEmptyAndTransformReturnsNonNilValueForSomeElementsInTrie_thenReturnsArrayWithMappedElementsWhereTransformReturnedNonNilValue() {
        whenIsNotEmpty()
        var countOfExecutions = 0
        let transform: (SutElement) -> Double? = {
            countOfExecutions += 1
            
            return $0.key.hasPrefix("s") ? Double($0.value) : nil
        }
        let expectedResult = givenKeys()
            .enumerated()
            .sorted(by: { $0.element < $1.element })
            .compactMap({ $0.element.hasPrefix("s") ? Double($0.offset) : nil })
        
        let result = sut.compactMap(transform)
        XCTAssertEqual(result, expectedResult)
        XCTAssertEqual(countOfExecutions, sut.count)
    }
    
    func testCompactMap_whenTransformThrows_thenRethrows() {
        whenIsNotEmpty()
        do {
            let _ = try sut.compactMap { _ in throw someError }
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - flatMap(_:) tests
    func testFlatMap_whenIsEmpty_thenTransformNeverExecutesAndReturnsEmptyArray() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        var countOfExecutions = 0
        let transform : (SutElement) -> Array<String> = { _ in
            countOfExecutions += 1
            
            return ["sea", "shells"]
        }
        
        let result = sut.flatMap(transform)
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testFlatMap_whenIsNotEmptyAndTransformReturnsAnEmptySequenceForEveryTrieElement_thenTransformExecutesOnEveryTrieElementAndReturnsAnEmptyArray() {
        whenIsNotEmpty()
        var capturedElements: Array<SutElement> = []
        let transform : (SutElement) -> Array<String> = {
            capturedElements.append($0)
            
            return []
        }
        let orderedElements = givenKeys().enumerated().sorted(by: { $0.element < $1.element }).map({ (key: $0.element, value: $0.offset) })
        
        let result = sut.flatMap(transform)
        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(capturedElements.elementsEqual(orderedElements, by: { $0.key == $1.key && $0.value == $1.value }))
    }
    
    func testFlatMap_whenIsNotEmptyAndTransformReturnsSequencesForEveryElementInTrie_thenReturnsFlatMappedTriesElements() {
        whenIsNotEmpty()
        let expectedResult = givenKeys()
            .enumerated()
            .sorted(by: { $0.element < $1.element })
            .flatMap({ Array<String>(repeating: $0.element, count: $0.offset) })
        let transform: (SutElement) -> Array<String> = {
            Array(repeating: $0.key, count: $0.value)
        }
        
        let result = sut.flatMap(transform)
        XCTAssertEqual(result, expectedResult)
    }
    
    func testFlatMap_whenTransformThrows_thenRethrows() {
        whenIsNotEmpty()
        do {
            let _ = try sut.flatMap({ (element) -> Array<String> in
                throw someError
            })
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - reduce(_:_:) tests
    func testReduce_whenIsEmpty_thenNextPartialResultNeverExecutesAndReturnsInitialResult() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        var countOfExecutions = 0
        let nextPartialResult: (Int, SutElement) -> Int = {
            countOfExecutions += 1
            
            return $0 + $1.value
        }
        
        let initialResult = Int.random(in: 10...100)
        let result = sut.reduce(initialResult, nextPartialResult)
        XCTAssertEqual(result, initialResult)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testReduce_whenIsNotEmpty_thenNextPartialResultExecutesOnEveryTrieElementAndReturnsReduceResult() {
        whenIsNotEmpty()
        let initialResult = Int.random(in: 10...100)
        var capturedElements: Array<SutElement> = []
        let nextPartialResult: (Int, SutElement) -> Int = {
            capturedElements.append($1)
            
            return $0 + $1.value
        }
        let sortedElements = givenKeys()
            .enumerated()
            .sorted(by: { $0.element < $1.element })
            .map({ (key: $0.element, value: $0.offset) })
        let expectedResult = sortedElements.reduce(initialResult, { $0 + $1.value })
        
        let result = sut.reduce(initialResult, nextPartialResult)
        XCTAssertEqual(result, expectedResult)
        XCTAssertTrue(capturedElements.elementsEqual(sortedElements, by: { $0.key == $1.key }))
    }
    
    func testReduce_whenNextPartialResultThrows_thenRethrows() {
        whenIsNotEmpty()
        do {
            let _ = try sut.reduce(0, {_, _ in throw someError })
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - reduce(into:_:) tests
    func testReduceInto_whenIsEmpty_thenUpdateAccumulatingResultNeverExecutesAndReturnsInitialResult() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        var countOfExecutions = 0
        let updateAccumulatingResult: (inout Int, SutElement) -> Void = {
            countOfExecutions += 1
            $0 += $1.value
        }
        
        let initialResult = Int.random(in: 10...100)
        let result = sut.reduce(into: initialResult, updateAccumulatingResult)
        XCTAssertEqual(result, initialResult)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testReduceInto_whenIsNotEmpty_thenUpdateAccumulatingResultExecutesOnEveryTrieElementAndReturnsReduceIntoResult() {
        whenIsNotEmpty()
        let initialResult = Int.random(in: 10...100)
        var capturedElements: Array<SutElement> = []
        let updateAccumulatingResult: (inout Int, SutElement) -> Void = {
            capturedElements.append($1)
            $0 += $1.value
        }
        let sortedElements = givenKeys()
            .enumerated()
            .sorted(by: { $0.element < $1.element })
            .map({ (key: $0.element, value: $0.offset) })
        let expectedResult = sortedElements.reduce(into: initialResult, { $0 += $1.value })
        
        let result = sut.reduce(into: initialResult, updateAccumulatingResult)
        XCTAssertEqual(result, expectedResult)
        XCTAssertTrue(capturedElements.elementsEqual(sortedElements, by: { $0.key == $1.key && $0.value == $1.value }))
    }
    
    func testReduceInto_whenUpdateAccumulatingResultThrows_thenRethrows() {
        whenIsNotEmpty()
        do {
            let _ = try sut.reduce(into: 0, {_, _ in throw someError })
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    // MARK: - filter(_:) tests
    func testFilter_whenIsEmpty_thenIsIncludedNeverExecutesAndReturnsEmptyArray() throws {
        try XCTSkipIf(sut.root != nil, "Trie must be empty for this test")
        var countOfExecutions = 0
        let isIncluded: (SutElement) -> Bool = { _ in
            countOfExecutions += 1
            
            return true
        }
        
        let result: Array<SutElement> = sut.filter(isIncluded)
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(countOfExecutions, 0)
    }
    
    func testFilter_whenIsNotEmptyAndIsIncludedReturnsFalseForEveryElementInTrie_thenIsIncludedExecutesOnEveryTrieElementAndReturnsEmtpyArray() {
        whenIsNotEmpty()
        var capturedElements: Array<SutElement> = []
        let isIncluded: (SutElement) -> Bool = {
            capturedElements.append($0)
            
            return false
        }
        let sortedElements = givenKeys()
            .enumerated()
            .sorted(by: { $0.element < $1.element })
            .map({ (key: $0.element, value: $0.offset) })
        
        let result: Array<SutElement> = sut.filter(isIncluded)
        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(capturedElements.elementsEqual(sortedElements, by: { $0.key == $1.key && $0.value == $1.value }))
    }
    
    func testFilter_whenIsNotEmptyAndIsIncludedReturnsTrueForSomeElementsInTrie_thenReturnsArrayContainingFilteredElementsFromTrie() {
        whenIsNotEmpty()
        let IsIncluded: (SutElement) -> Bool = {
            $0.key.hasPrefix("sh")
        }
        let expectedResult = givenKeys()
            .enumerated()
            .sorted(by: { $0.element < $1.element })
            .map({ (key: $0.element, value: $0.offset) })
            .filter(IsIncluded)
        
        let result: Array<SutElement> = sut.filter(IsIncluded)
        XCTAssertTrue(result.elementsEqual(expectedResult, by: { $0.key == $1.key && $0.value == $1.value }))
    }
    
    func testFilter_whenIsIncludedThrows_thenRethrows() {
        whenIsNotEmpty()
        do {
            let _: Array<SutElement> = try sut.filter { _ in  throw someError }
            XCTFail("Didn't rethrow")
        } catch {
            XCTAssertEqual(error as NSError, someError)
        }
    }
    
    func testReversed() {
        whenIsNotEmpty()
        let expectedResult = givenKeys()
            .enumerated().sorted(by: { $0.element > $1.element })
            .map({ (key: $0.element, value: $0.offset) })
        let reversed = sut.reversed()
        XCTAssertTrue(reversed.elementsEqual(expectedResult, by: { $0.key == $1.key && $0.value == $1.value }))
    }
    
}
