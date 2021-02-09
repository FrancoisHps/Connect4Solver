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
 * Transposition Table is a simple hash map with fixed storage size.
 * In case of collision we keep the last entry and overide the previous one.
 *
 * We use 56-bit keys and 8-bit non-null values
 */
final internal class TranspositionTable {

    private var table : UnsafeMutablePointer<UInt>
    private var size : Int

    /**
     * Allocate and initialize to zero a mutable pointer.
     * We don't use UnsafeMutableBufferPointer because we don't need collection protocol
     * We'll store a 56 bit key in low bytes  and an 8 bit value in high byte
     * - parameter size: number of entries
     */
    internal init(size: Int) {
        self.size = size
        table = UnsafeMutablePointer<UInt>.allocate(capacity: size)
        table.initialize(repeating: .zero, count: size)
    }

    deinit {
        table.deallocate()
    }

    /**
     * Compute the index in the transition table for the given key.
     */
    private func index(for key: UInt) -> Int {
        Int(bitPattern: key) % size
    }

    /**
     * Store a value for a given key
     * - parameter key: 56-bit key
     * - parameter value: non-null 8-bit value. null (0) value are used to encode missing data.
     */
    internal func put(key: UInt, value: Int) {
        assert(key < (UInt(1) << 56))
        assert(value < (1 << 8))
        assert(value > -(1 << 8))

        let position = index(for: key)
        let entryPointer = table.advanced(by: position)

        entryPointer.pointee = (key + (UInt(bitPattern: value) << 56))
    }

    /**
     * Get the value of a key
     * - parameter key: 56-bit key
     * - parameter value: 8-bit value associated with the key if present, 0 otherwise.
     */
    internal func get(key: UInt) -> Int {
        assert(key < (UInt(1) << 56))

        let position = index(for: key)
        let entry = table.advanced(by: position).pointee

        guard entry & ((1 << 56) - 1) == key else { return 0 }

        return Int(bitPattern: (entry >> 56))
    }

    /**
     * Empty the Transition Table.
     */
    internal func reset() {
        table.assign(repeating: .zero, count: size)
    }
}
