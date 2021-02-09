//
//  TranspositionTableTests.swift
//  Connect4Tests
//
//  Created by Francois on 09/02/2021.
//

import XCTest
@testable import Connect4

class TranspositionTableTests: XCTestCase {

    func testInit() throws {
        let table = TranspositionTable()
        XCTAssertEqual(table.get(key: 42), 0)
    }

    func testPutAndGet() throws {
        let table = TranspositionTable()
        table.put(key:42, value: 1)
        table.put(key:96, value: 2)

        XCTAssertEqual(table.get(key: 42), 1)
        XCTAssertEqual(table.get(key: 96), 2)

        table.put(key: 42 + (1 << 23) + 9, value: 3)
        XCTAssertEqual(table.get(key: 42), 0)
        XCTAssertEqual(table.get(key: 42 + (1 << 23) + 9), 3)
    }

    func testReset() throws {
        //        let table = TranspositionTable(size: 97)
        let table = TranspositionTable()
        table.put(key:42, value: 1)
        table.reset()

        XCTAssertEqual(table.get(key: 42), 0)
    }
}
