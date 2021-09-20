//
//  ThreeWaysTrie+Codable.swift
//  ThreeWaysTrie
//
//  Created by Valeriano Della Longa on 2021/09/15.
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

import Foundation

extension ThreeWaysTrie: Codable where Value: Codable {
    public enum Error: Swift.Error {
        case emptyKey
        
    }
    
    fileprivate struct CodingKeys: CodingKey {
        let stringValue: String
        
        let intValue: Int?
        
        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = Int(stringValue)
        }
        
        init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
        
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        for codingKey in container.allKeys {
            guard
                !codingKey.stringValue.isEmpty
            else { throw Error.emptyKey }
            
            let value = try container.decode(Value.self, forKey: codingKey)
            self.root = self._put(node: self.root, key: codingKey.stringValue, value: value, index: codingKey.stringValue.startIndex, uniquingKeysWith: { _, _ in preconditionFailure("Keys must be unique.") })
        }
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try root?._inOrderVisit({ _, key, node in
            guard
                let value = node.value
            else { return }
            
            let codingKey = CodingKeys(stringValue: key)!
            try container.encode(value, forKey: codingKey)
        })
    }
    
}

