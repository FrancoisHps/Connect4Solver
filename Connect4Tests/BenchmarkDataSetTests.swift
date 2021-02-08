/*
 * This file is part of my swift adapation of Connect4 Game Solver
 * <http://connect4.gamesolver.org> by Pascal Pons <contact@gamesolver.org>
 * Copyright (C) 2021 Francois Heuchamps
 *
 * Connect4 Game Solver is free software: you can redistribute it and/or
 * modify it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * Connect4 Game Solver is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with Connect4 Game Solver. If not, see <http://www.gnu.org/licenses/>.
 */

import XCTest
import Connect4

class BenchmarkDataSetTests: XCTestCase {

    func testBenchmarkDataSet() throws {
        let dataSet = BenchmarkDataSet(index: 0)
        XCTAssertEqual(dataSet.count, 1000)
    }

    func testCollectionIteration() throws {
        var counter = 0
        for _ in BenchmarkDataSet(index: 0) {
            counter += 1
        }

        XCTAssertEqual(counter, 1000)
    }
}
