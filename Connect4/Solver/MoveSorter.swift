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
 * This struct helps sorting the next moves
 *
 * You have to add moves first with their score
 * then you can get them back in decreasing score
 *
 * This struct implement an insertion sort that is in practice very
 * efficient for small number of move to sort (max is Position.Dimension.width)
 * and also efficient if the move are pushed in approximatively increasing
 * order which can be acheived by using a simpler colum ordering heuristic.
 */
internal struct MoveSorter {

    /// Each entry contains a move and his score.
    fileprivate typealias Entry = (move: UInt, score: Int)

    /// create a move sorter pool which can contain a move sorter for at most Position.Dimension.area entries
//    static private var moveSorterPool : UnsafeMutablePointer<Entry> =  {
//        let size = Position.Dimension.area * Position.Dimension.width
//        let pool = UnsafeMutablePointer<Entry>.allocate(capacity: size)
//        return pool
//    }()

    internal struct MoveSorterPool {
        fileprivate var moveSorterPool : UnsafeMutablePointer<Entry> =  {
            let size = Position.Dimension.area * Position.Dimension.width
            let pool = UnsafeMutablePointer<Entry>.allocate(capacity: size)
            return pool
        }()
    }

    /// Pointer to the appropriate container
    private var entries : UnsafeMutablePointer<Entry>

    /// number of stored moves
    private var count: Int

    /**
     * Initiate a moveSorter container
     * - parameter depth: depth in the search tree - Must be in [0..<Position.Dimension.area]
     */
    internal init(at depth: Int, using pool: MoveSorterPool) {
        assert(depth >= 0 && depth < Position.Dimension.area)
        entries = pool.moveSorterPool.advanced(by: depth * Position.Dimension.width)
        count = 0
    }

    /**
     * Add a move in the container with its score.
     * You cannot add more than Position.Dimension.width
     */
    internal mutating func add(move: UInt, score: Int) {
        assert(count < Position.Dimension.width)
        var position = count
        count += 1

        while position > 0 && entries.advanced(by: position-1).pointee.score > score {
            entries.advanced(by: position).pointee = entries.advanced(by: position-1).pointee
            position -= 1
        }

        entries.advanced(by: position).pointee = (move: move, score: score)
    }
}

extension MoveSorter : Sequence, IteratorProtocol {

    /**
     * Advances to the next element and returns it, or nil if no next element exists.
     */
    internal mutating func next() -> UInt? {
        guard count != 0 else { return nil }

        count -= 1
        return entries.advanced(by: count).pointee.move
    }
}
