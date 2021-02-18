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
@testable import Connect4

class PositionTests: XCTestCase {

    let moves = "2252576253462244111563365343671351441"
    var position : Position? = nil

    override func setUpWithError() throws {
        position = Position(moves: moves)
    }

    func testInit() throws {
        let position = Position()
        XCTAssertEqual(position.numberOfMoves, 0)
        XCTAssertEqual(position.numberOfMoves, 0)
        XCTAssertFalse(position.draw)
    }

    func testInitMoves() throws {
        guard let position = position else {
            XCTFail("can't parse moves \(moves)")
            return
        }

        XCTAssertEqual(position.numberOfMoves, moves.count)
        XCTAssertFalse(position.draw)

        XCTAssertEqual(position.debugDescription,
                       "X.O.O.O.X. . " + "\n" +
                       "O.X.O.X.X.X. " + "\n" +
                       "X.O.O.X.O.O. " + "\n" +
                       "X.O.X.O.X.X. " + "\n" +
                       "O.O.O.X.X.O.O" + "\n" +
                       "X.X.O.X.X.X.O"
        )
    }

    func testCanPlayInColumn() throws {
        guard let position = position else { return }

        for column in 0...4 {
            XCTAssertFalse(position.canPlay(in: column), "can play in column \(column)")
        }

        XCTAssertTrue(position.canPlay(in: 5), "can't play in column \(5)")
        XCTAssertTrue(position.canPlay(in: 6), "can't play in column \(6)")

    }

    func testPlayInColumn() throws {
        guard var position = position else { return }

        position.play(in: 5)
        XCTAssertFalse(position.canPlay(in: 5))

        position.play(in: 6)
        XCTAssertTrue(position.canPlay(in: 6))
    }


    func testWinningMove() throws {
        guard var position = position else { return }

        position.play(in: 5)
        position.play(in: 6)
        position.play(in: 6)

        XCTAssertTrue(position.isWinnngMove(in: 6), "can't win in column \(5)")
    }

    func testWinningVerticalMove() throws {
        var position = Position()

        position.play(in: 2)
        position.play(in: 3)
        position.play(in: 2)
        position.play(in: 3)
        position.play(in: 2)
        position.play(in: 3)

        XCTAssertTrue(position.isWinnngMove(in: 2), "can't win in column \(2)")
    }

    func testSymetry() throws {
        guard let position = position else { return }
        guard let symetric = Position(moves: "6636312635426644777325523545217537447") else { return }

        XCTAssertEqual(symetric.debugDescription,
                        " . .X.O.O.O.X" + "\n" +
                        " .X.X.X.O.X.O" + "\n" +
                        " .O.O.X.O.O.X" + "\n" +
                        " .X.X.O.X.O.X" + "\n" +
                        "O.O.X.X.O.O.O" + "\n" +
                        "O.X.X.X.O.X.X"
        )

        XCTAssertEqual(position.key3, symetric.key3)
    }
}
