//
//  ThreeWaysTrieCodableTests.swift
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

final class ThreeWaysTrieCodableTests: BaseTrieTestClass {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    func testEncodeThanDecode() {
        do {
            sut = ThreeWaysTrie()
            var data = try encoder.encode(sut)
            var decoded = try decoder.decode(ThreeWaysTrie<Int>.self, from: data)
            XCTAssertEqual(sut, decoded)
            
            whenIsNotEmpty()
            data = try encoder.encode(sut)
            decoded = try decoder.decode(ThreeWaysTrie<Int>.self, from: data)
            XCTAssertEqual(sut, decoded)
        } catch {
            XCTFail("Thrown error: \(error)")
        }
    }
    
    func testDecodeWhenDecodesEmptyKey_thenThrowsError() {
        let data = try! JSONSerialization.data(withJSONObject: malformedJSON, options: .prettyPrinted)
        do {
            sut = try decoder.decode(ThreeWaysTrie<Int>.self, from: data)
            XCTFail("Didn't throw error")
        } catch {
            XCTAssertEqual(error as NSError, ThreeWaysTrie<Int>.Error.emptyKey as NSError)
        }
    }
    
}
