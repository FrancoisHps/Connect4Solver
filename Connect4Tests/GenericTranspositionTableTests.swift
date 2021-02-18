//
//  GenericTranspositionTableTests.swift
//  Connect4Tests
//
//  Created by Francois on 13/02/2021.
//

import XCTest
@testable import Connect4

class GenericTranspositionTableTests: XCTestCase {
    func testInit() throws {
        let table = GenericTranspositionTable<UInt8, Int16>(logSize: 4) // size = 17
        XCTAssertEqual(table.get(key: 42), 0)
    }

    func testPutAndGet() throws {
        let table = GenericTranspositionTable<UInt8, Int16>(logSize: 4)
        table.put(key:42, value: 1)
        table.put(key:96, value: 2)

        XCTAssertEqual(table.get(key: 42), 1)
        XCTAssertEqual(table.get(key: 96), 2)

        table.put(key: 8, value: 3) // 42 % 17 = 8
        XCTAssertEqual(table.get(key: 42), 0)
        XCTAssertEqual(table.get(key: 8), 3)
    }

    func testReset() throws {
        let table = GenericTranspositionTable<UInt8, Int16>(logSize: 4)
        table.put(key:42, value: 1)
        table.reset()

        XCTAssertEqual(table.get(key: 42), 0)
    }
}
