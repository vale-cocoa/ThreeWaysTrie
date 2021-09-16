//
//  TestsHelpers.swift
//  ThreeWaysTrieTests
//
//  Created by Valeriano Della Longa on 2021/09/06.
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

let someError = NSError(domain: "com.vdl.threewaystrie", code: 1, userInfo: nil)

fileprivate let malformedJSON: [String : Any] = [
    "char" : "" as Any,
    "value" : 1 as Any,
    "count" : 1 as Any,
]

func givenKeys() -> Array<String> {
    //let phrase = "she sells seashells by the seashore"
    let phrase = "she sells seashells by the shoreline"
    
    return phrase.components(separatedBy: " ")
}

func assertAreEqualNodesButNotSameInstance<Value>(lhs: ThreeWaysTrie<Value>.Node?, rhs: ThreeWaysTrie<Value>.Node?, file: StaticString = #file, line: UInt = #line) where Value: Equatable {
    switch (lhs, rhs) {
    case (nil, nil): return
    
    case (.some(let l), .some(let r)):
        guard
            l !== r
        else {
            XCTFail("Nodes are same istance", file: file, line: line)
            return
        }
        
        guard
            l.char == r.char,
            l.value == r.value,
            l.count == r.count
        else { fallthrough }
        
        assertAreEqualNodesButNotSameInstance(lhs: l.left, rhs: r.left, file: file, line: line)
        assertAreEqualNodesButNotSameInstance(lhs: l.mid, rhs: r.mid, file: file, line: line)
        assertAreEqualNodesButNotSameInstance(lhs: l.right, rhs: r.right, file: file, line: line)
        
    default: XCTFail("Nodes are not equal", file: file, line: line)
    }
}

func assertCountValuesAreValid<Value>(root: ThreeWaysTrie<Value>.Node?, file: StaticString = #file, line: UInt = #line) {
    guard
        let n = root
    else { return }
    
    var expectedCount = n.value != nil ? 1 : 0
    expectedCount += n.left?.count ?? 0
    expectedCount += n.mid?.count ?? 0
    expectedCount += n.right?.count ?? 0
    if n.count != expectedCount {
        XCTFail("Count is not right for node: \(n): expected: \(expectedCount), got: \(n.count)", file: file, line: line)
    }
    assertCountValuesAreValid(root: n.left, file: file, line: line)
    assertCountValuesAreValid(root: n.mid, file: file, line: line)
    assertCountValuesAreValid(root: n.right, file: file, line: line)
}

func assertAreEqualNodes<Value>(lhs: ThreeWaysTrie<Value>.Node?, rhs: ThreeWaysTrie<Value>.Node?, file: StaticString = #file, line: UInt = #line, message: String? = nil) where Value: Equatable {
    guard
        lhs !== rhs
    else { return }
    
    var msg = "Nodes are not equal:\n"
    let prevMsg = (message != nil ? " – \(message!)\n" : "")
    switch (lhs, rhs) {
    case (nil, nil): return
    case (.some(let l), .some(let r)):
        guard
            l.char == r.char,
            l.count == r.count,
            l.value == r.value
        else {
            msg += "lhs.char: \(l.char) — rhs.char: \(r.char)\n"
            msg += "lhs.count: \(l.count) - rhs.count\(r.count)\n"
            msg += "lhs.value: \(String(describing: l.value)) - rhs.value: \(String(describing: r.value))\n"
            msg += prevMsg
            fallthrough
        }
        
        assertAreEqualNodes(lhs: l.left, rhs: r.left, file: file, line: line, message: msg + "Nodes' lefts are not equal.\n" + prevMsg)
        assertAreEqualNodes(lhs: l.mid, rhs: r.mid, file: file, line: line, message: msg + "Nodes' mids are not equal\n" + prevMsg)
        assertAreEqualNodes(lhs: l.right, rhs: r.right, file: file, line: line, message: msg + "Nodes' rights are not equal\n" + prevMsg)
    default: XCTFail(msg, file: file, line: line)
    }
}

internal class BaseTrieTestClass: XCTestCase {
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
        sut.root = sut._put(node: sut.root, key: key, value: 1, index: key.startIndex, uniquingKeysWith: { _, latest in latest })
    }
    
    func whenIsNotEmpty() {
        for (value, key) in givenKeys().enumerated() {
            sut.root = sut._put(node: sut.root, key: key, value: value, index: key.startIndex, uniquingKeysWith: { _, latest in latest })
        }
    }
    
}

final class WrappedValue: NSCopying {
    var value: NSArray
    
    init(_ value: Array<Any>) {
        self.value = value as NSArray
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let clone = WrappedValue(value.copy(with: zone) as! Array)
        
        return clone
    }
    
}
