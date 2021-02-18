//
//  BinaryInteger+PrimeTests.swift
//  Connect4Tests
//
//  Created by Francois on 13/02/2021.
//

import XCTest
@testable import Connect4

class BinaryInteger_PrimeTests: XCTestCase {

    func testNextPrime() throws {
        let value = 1 << 23

        XCTAssertEqual(value.nextPrime, value + 9)
    }

    func testHasFactor() throws {
        let value = 17 * 97
        
        XCTAssertTrue(value.hasFactor(min: 2, max: 20))
        XCTAssertFalse(value.hasFactor(min: 20, max: 80))
    }

    func testMed() throws {
        XCTAssertEqual(med(4, 9), 6)
        XCTAssertEqual(med(-1, -5), -3)
    }
}
