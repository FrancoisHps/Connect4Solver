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

class SolverTests: XCTestCase {

    let moves = "427566236745127177115664464254"
    var position : Position? = nil

    override func setUpWithError() throws {
        position = Position(moves: moves)
    }

    func testSolve() throws {
        guard let position = position else { return }
        XCTAssertEqual(Solver().solve(position: position), 2)
    }

    func testWeakSolve() throws {
        guard let position = position else { return }
        XCTAssertEqual(Solver().solve(position: position, weak: true), 1)
    }

    func testAnalyze() throws {
        guard let position = position else { return }
        let scores = Solver().analyze(position: position, weak: false)

        XCTAssertEqual(scores, [2, 2, 1, nil, 2, nil, 2])
    }

    func testWeakAnalyze() throws {
        guard let position = position else { return }
        let scores = Solver().analyze(position: position, weak: true)

        XCTAssertEqual(scores, [1, 1, 1, nil, 1, nil, 1])
    }
}
