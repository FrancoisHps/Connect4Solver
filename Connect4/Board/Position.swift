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
 * Functions are relative to the current player to play.
 * Position containing aligment are not supported by this class.
 *
 * A binary bitboard representationis used.
 * Each column is encoded on height +1 bits.
 *
 * Example of bit order to encode for a 7x6 board
 * ````
 * .  .  .  .  .  .  .
 * 5 12 19 26 33 40 47
 * 4 11 18 25 32 39 46
 * 3 10 17 24 31 38 45
 * 2  9 16 23 30 37 44
 * 1  8 15 22 29 36 43
 * 0  7 14 21 28 35 42
 * ````
 * Position is stored as
 * - a bitboard "mask" with 1 on any color stones
 * - a bitboard "currentPosition" with 1 on stones of current player
 *
 * "currentPosition" bitboard can be transformed into a compact and non ambiguous key
 * by adding an extra bit on top of the last non empty cell of each column.
 * This allow to identify all the empty cells whithout needing "mask" bitboard
 *
 * - currentPosition "x" = 1, opponent "o" = 0
 * ````
 * board     position  mask      key       bottom
 *           0000000   0000000   0000000   0000000
 * .......   0000000   0000000   0001000   0000000
 * ...o...   0000000   0001000   0010000   0000000
 * ..xx...   0011000   0011000   0011000   0000000
 * ..ox...   0001000   0011000   0001100   0000000
 * ..oox..   0000100   0011100   0000110   0000000
 * ..oxxo.   0001100   0011110   1101101   1111111
 * ````
 * - currentPosition "o" = 1, opponent "x" = 0
 * ````
 * board     position  mask      key       bottom
 *           0000000   0000000   0001000   0000000
 * ...x...   0000000   0001000   0000000   0000000
 * ...o...   0001000   0001000   0011000   0000000
 * ..xx...   0000000   0011000   0000000   0000000
 * ..ox...   0010000   0011000   0010100   0000000
 * ..oox..   0011000   0011100   0011010   0000000
 * ..oxxo.   0010010   0011110   1110011   1111111
 * ````
 * key is an unique representation of a board key = position + mask + bottom
 * in practice, as bottom is constant, key = position + mask is also a
 * non-ambigous representation of the position.
 */
public struct Position {

    // MARK: - Static Properties

    /// Dimensions of Connect 4 Board
    struct Dimension {
        static let width = 7
        static let height = 6
        static let area = width * height
    }

    // MARK: - Properties

    /// Binary bitboard representation : 1 on stones of current player
    private var currentPosition : UInt

    /// Binary bitboard representation : 1 on any color stones
    private var mask : UInt

    /// Number of moves played since the beinning of the game.
    public var numberOfMoves : Int

    /// compact representation of a position on width*(height+1) bits.
    internal var key: UInt {
        currentPosition + mask
    }

    // MARK: - Init

    /// Create a new empty board.
    public init() {
        currentPosition = 0
        mask = 0
        numberOfMoves = 0

        // As swift doesn't have static assert, we check all conditions here
        assert(Dimension.width < 10, "Board's width must be less than 10")
        assert(Dimension.area + Dimension.width <= UInt.bitWidth, "Board does not fit in \(UInt.bitWidth) bits bitboard")
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
    public init?(moves: String) {
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

    // MARK: - Board functions

    /**
     Indicates whether a column is playable.
     - parameter column: 0-based index of column to play
     - returns: true if the column is playable, false if the column is already full.
     */
    public func canPlay(in column: Int) -> Bool {
        (mask & Self.topMask(for: column)) == 0
    }

    /**
     * Plays a playable column.
     *
     * This function **should not** be called on a non-playable column or a column making an alignment.
     * - parameter column: 0-based index of a playable column.
     */
    public mutating func play(in column: Int) {
        assert(canPlay(in: column), "play should not be called on a non playable column")
        assert(!isWinnngMove(in: column), "play should not be called on a column making an alignment")
        currentPosition ^= mask
        mask |= mask + Self.bottomMask(for: column)
        numberOfMoves += 1
    }

    /**
     * Indicates whether the current player wins by playing a given column.
     *
     * This function should never be called on a non-playable column.
     * - parameter column: 0-based index of a playable column.
     * - returns: true if current player makes an alignment by playing the corresponding column col.
     */
    public func isWinnngMove(in column: Int) -> Bool {
        assert(canPlay(in: column), "isWinnngMove should not be called on a non playable column")
        var position = currentPosition
        position |= (mask + Self.bottomMask(for: column)) & Self.columnMask(for: column)
        return Self.alignment(position: position);
    }

    /// True if draw game, otherwise false
    public var draw: Bool {
        numberOfMoves == Dimension.area
    }

    // MARK: - Anticipating winning move

    /**
     * Return a bitmap of all the possible next moves the do not lose in one turn.
     * A losing move is a move leaving the possibility for the opponent to win directly.
     *
     * Warning this function is intended to test position where you cannot win in one turn
     * If you have a winning move, this function can miss it and prefer to prevent the opponent
     * to make an alignment.
     */
    internal var possibleNonLoosingMoves : UInt {
        assert(!canWinNext)
        var possibleMask = possible
        let opponentWin = opponentWinningPosition
        let forcedMoves = possibleMask & opponentWin

        if forcedMoves != 0 {
            if (forcedMoves & (forcedMoves - 1)) != 0 {
                // the opponnent has two winning moves and you cannot stop him
                return 0
            }
            else {
                // enforce to play the single forced move
                possibleMask = forcedMoves;
            }
        }

        // avoid to play below an opponent winning spot
        return possibleMask & ~(opponentWin >> 1)
    }

    /// true if current player can win next move
    internal var canWinNext : Bool {
        winningPosition & possible != 0;
    }

    /// a bitmask of the possible winning positions for the current player
    private var winningPosition : UInt {
        computeWinningPosition(position: currentPosition, mask: mask)
    }

    /// a bitmask of the possible winning positions for the opponent
    private var opponentWinningPosition : UInt {
        computeWinningPosition(position: currentPosition ^ mask, mask: mask)
    }

    /// a bitmask of all possibles moves
    private var possible : UInt {
        (mask + Self.bottomMask) & Self.boardMask;
    }

    /**
     * Identify all winning positions of a given board. Meaning all open ended 3-aligments.
     * - parameter position: position for the current player
     * - parameter mask: position for all players
     * - returns: bitmask containg all open ended 3-alignements
     */
    private func computeWinningPosition(position: UInt, mask: UInt) -> UInt {
        // vertical;
        var r = (position << 1) & (position << 2) & (position << 3)

        //horizontal
        var p = (position << (Dimension.height + 1)) & (position << (2 * (Dimension.height + 1)))
        r |= p & (position << (3 * (Dimension.height + 1)))
        r |= p & (position >> (Dimension.height + 1))
        p = (position >> (Dimension.height + 1)) & (position >> (2 * (Dimension.height + 1)))
        r |= p & (position << (Dimension.height + 1))
        r |= p & (position >> (3 * (Dimension.height + 1)))

        //diagonal 1
        p = (position << (Dimension.height)) & (position << (2 * Dimension.height))
        r |= p & (position << (3 * Dimension.height))
        r |= p & (position >> Dimension.height)
        p = (position >> Dimension.height) & (position >> (2 * Dimension.height))
        r |= p & (position << Dimension.height)
        r |= p & (position >> (3 * Dimension.height))

        //diagonal 2
        p = (position << (Dimension.height + 2)) & (position << (2 * (Dimension.height + 2)))
        r |= p & (position << (3 * (Dimension.height + 2)))
        r |= p & (position >> (Dimension.height + 2))
        p = (position >> (Dimension.height + 2)) & (position >> (2 * (Dimension.height + 2)))
        r |= p & (position << (Dimension.height + 2))
        r |= p & (position >> (3 * (Dimension.height + 2)))

        return r & (Self.boardMask ^ mask)
    }

    static private var bottomMask = bottom(width: Dimension.width, height: Dimension.height);
    static private var boardMask = bottomMask * ((1 << Dimension.height) - 1);

    static private func bottom(width: Int, height: Int) -> UInt {
        width == 0 ? 0 : bottom(width: width - 1, height: height) | UInt(1) << ((width - 1) * (height + 1));
    }

    // MARK: - Better Move Ordering
    internal func moveScore(move: UInt) -> Int {
        computeWinningPosition(position: currentPosition | move, mask: mask)
            .nonzeroBitCount
    }

    internal mutating func play(move: UInt) {
        currentPosition ^= mask
        mask |= move
        numberOfMoves += 1
    }

    // MARK: - Static bit functions

    /**
     * Test an alignment for current player (identified by one in the given bitboard position)
     * - parameter position: a bitboard position of a player's cells.
     * - returns:
     *  true if the player has a 4-alignment.
     */
    static private func alignment(position: UInt)-> Bool {
        // horizontal
        var m = position & (position >> (Dimension.height + 1));
        if(m & (m >> (2 * (Dimension.height + 1)))) != 0 { return true }

        // diagonal 1
        m = position & (position >> Dimension.height);
        if(m & (m >> (2 * Dimension.height))) != 0 { return true }

        // diagonal 2
        m = position & (position >> (Dimension.height + 2));
        if(m & (m >> (2 * (Dimension.height + 2)))) != 0 { return true }

        // vertical;
        m = position & (position >> 1);
        if(m & (m >> 2)) != 0 { return true }

        return false;
    }

    /// Return a bitmask containg a single 1 corresponding to the top cel of a given column
    static private func topMask(for column: Int)-> UInt {
        (UInt(1) << (Dimension.height - 1)) << (column * (Dimension.height + 1))
    }

    /// Return a bitmask containg a single 1 corresponding to the bottom cell of a given column
    static private func bottomMask(for column: Int)-> UInt {
        UInt(1) << (column * (Dimension.height + 1))
    }

    /// Return a bitmask 1 on all the cells of a given column
    static func columnMask(for column: Int)-> UInt {
        ((UInt(1) << Dimension.height) - 1) << (column * (Dimension.height + 1))
    }
}

// MARK: - CustomDebugStringConvertible

extension Position : CustomDebugStringConvertible  {
    public var debugDescription: String {
        var description = ""

        (0 ..< Dimension.height).reversed().forEach { row in
            (0 ..< Dimension.width).forEach  { column in
                let current = currentPosition & Self.columnMask(for: column) & (1 << (column * (Dimension.height + 1) + row))
                let filled = mask & Self.columnMask(for: column) & (1 << (column * (Dimension.height + 1) + row))

                var chip = Chip.none
                if filled != 0 {
                    chip = ((current == 0) && (numberOfMoves % 2 != 0)) ||
                           ((current != 0) && (numberOfMoves % 2 == 0)) ? .player1 : .player2
                }
                description += chip.debugDescription

                if column + 1 < Dimension.width { description += "." }
            }

            if row > 0 { description += "\n"}
        }

        return description
    }
}

