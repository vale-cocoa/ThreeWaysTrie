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

final class ThreeWaysTrieTests: XCTestCase {
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
    func whenRootIsNotNil() {
        let key = "shells"
        sut.root = sut._put(node: sut.root, key: key, value: 1, index: key.startIndex, uniquingKeysWith: { _, _ in fatalError() })
    }
    
    // MARK: - Tests
    func testInit() {
        sut = ThreeWaysTrie()
        
        XCTAssertNotNil(sut)
        XCTAssertNil(sut.root)
    }
    
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
        XCTAssertFalse(sut.root === cp.root)
        XCTAssertEqual(sut.root, cp.root)
    }
    
}
