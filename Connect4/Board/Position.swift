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

import Foundation

/**
 * A class storing a Connect 4 position.
 * All function are relative to the current player to play.
 *
 * Position containing aligment are not supported by this class
 * as it simplifies implementation and there is no point solving an already won position
 */
public final class Position {

    // MARK: - Properties

    // Dimension of Connect4 Position
    struct Dimension {
        static let width = 7
        static let height = 6
        static let area = width * height
    }

    /// Board
    private var board : [Chip]

    /// Number of stones per column
    private var height : [Int]

    /// Number of moves played since the beinning of the game.
    public var numberOfMoves = 0

    // MARK: - Object Lifecyle

    public init() {
        board = Array(repeating: .none, count: Dimension.width * Dimension.height)
        height = Array(repeating: 0, count: Dimension.width)
    }

    /**
     * Create a new instance of the given board.
     * - parameter board: The board to be copied.
     */
    public init(position : Position) {
        // copy cells and player
        board = position.board

        // copy fillig array too
        height = position.height

        // copy number of moves
        numberOfMoves = position.numberOfMoves
    }

    /**
     * Plays a sequence of successive played columns, mainly used to initilize a board.
     * - parameter moves: a string of digits corresponding to the 1-based index of the column played.
     *
     * Processing will stop at first invalid move that can be:
     *   - invalid character (non digit, or digit >= WIDTH)
     *   - playing a colum that is already full
     *   - playing a column that makes an aligment (we only solve non).
     */
    public convenience init?(moves: String) {
        self.init()

        for character in moves {
            let column = Int(character.unicodeScalars.first!.value) - Int(Unicode.Scalar("0").value) - 1

            guard column >= 0, column < Dimension.width,
                  canPlay(in: column),
                  !isWinnngMove(in: column)
            else { return nil }

            play(in: column)
        }
    }

    /**
    * Subscript (column major order)
    */
    public subscript(column: Int, row: Int) -> Chip {
        get {
            board[row + column * Dimension.height]
        }
        set {
            board[row + column * Dimension.height] = newValue
        }
    }

    // MARK: - Board functions

    /**
     * Indicates whether a column is playable.
     * - parameter column: 0-based index of column to play
     * - returns:  true if the column is playable, false if the column is already full.
     */
    public func canPlay(in column: Int) -> Bool {
        height[column] < Dimension.height
    }

    /// Check for draw game
    public var draw: Bool {
        numberOfMoves == Dimension.area
    }

    /// Current player : player1 or player2
    public var player : Chip {
        numberOfMoves % 2 == 0 ? Chip.player1 : Chip.player2
    }

    /**
     * Indicates whether the current player wins by playing a given column.
     * This function should never be called on a non-playable column.
     * - parameter column: 0-based index of a playable column.
     * - returns: true if current player makes an alignment by playing the corresponding column col.
     */
    public func isWinnngMove(in column: Int) -> Bool {
        let currentPlayer = player
        let row = height[column]

        // check for vertical alignments
        if row >= 3
            && self[column, row - 1] == currentPlayer
            && self[column, row - 2] == currentPlayer
            && self[column, row - 3] == currentPlayer {
            return true
        }

        // Iterate on horizontal (dy = 0) or two diagonal directions (dy = -1 or dy = 1).
        for dy in -1...1 {
            // counter of the number of stones of current player surronding the played stone in tested direction.
            var numberOfPlayerStone = 0

            // count continuous stones of current player on the left, then right of the played column.
            for dx in [-1, 1] {

                var x = column + dx
                var y = row + dx * dy

                while x >= 0 && x < Dimension.width && y >= 0 && y < Dimension.height && self[x,y] == currentPlayer {
                    x += dx;
                    y += dx*dy;

                    numberOfPlayerStone += 1
                }
            }

            if numberOfPlayerStone >= 3 {
                return true
            }
        }

        return false
    }

    /**
     * Plays a playable column.
     * This function should not be called on a non-playable column or a column making an alignment.
     *
     * - parameter column: 0-based index of a playable column.
     */
    public func play(in column: Int) {
        let row = height[column]
        self[column, row] = player
        height[column] += 1
        numberOfMoves += 1
    }
}

// MARK: - CustomDebugStringConvertible

extension Position : CustomDebugStringConvertible  {
    public var debugDescription: String {
        var description = ""

        (0 ..< Dimension.height).reversed().forEach { row in
            (0 ..< Dimension.width).forEach  { column in
                let chip = self[column, row]
                description += chip.debugDescription

                if column + 1 < Dimension.width { description += "." }
            }

            if row > 0 { description += "\n"}
        }

        return description
    }
}
