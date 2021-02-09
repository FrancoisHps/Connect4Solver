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
 */
final internal class TranspositionTable {

    typealias KeyType = UInt32
    typealias ValueType = Int8

    private var keys : UnsafeMutablePointer<KeyType>
    private var values : UnsafeMutablePointer<ValueType>
    private static var size = 1 << 23 + 9
 
    /**
     * Allocate and initialize to zero a mutable pointer.
     * We don't use UnsafeMutableBufferPointer because we don't need collection protocol
     * We'll store a 56 bit key in low bytes  and an 8 bit value in high byte
     * - parameter size: number of entries
     */
    internal init() {
        keys = UnsafeMutablePointer<KeyType>.allocate(capacity: Self.size)
        keys.initialize(repeating: .zero, count: Self.size)
        values = UnsafeMutablePointer<ValueType>.allocate(capacity: Self.size)
        values.initialize(repeating: .zero, count: Self.size)
    }

    deinit {
        keys.deallocate()
        values.deallocate()
    }

    /**
     * Compute the index in the transition table for the given key.
     */
    private func index(for key: UInt) -> Int {
        Int(bitPattern: key) % Self.size
    }

    /**
     * Store a value for a given key
     * - parameter key: must be less than key_size bits.
     * - parameter value: must be less than value_size bits. null (0) value is used to encode missing data
     */
    internal func put(key: UInt, value: Int) {
        assert(value <= ValueType.max)
        assert(value >= ValueType.min)

        let position = index(for: key)

        keys.advanced(by: position).pointee = KeyType(truncatingIfNeeded: key)
        values.advanced(by: position).pointee = ValueType(truncatingIfNeeded: value)
    }

    /**
     * Get the value of a key
     * - parameter key: must be less than key_size bits.
     * - returns: value_size bits value associated with the key if present, 0 otherwise.
     */
    internal func get(key: UInt) -> Int {
        let position = index(for: key)

        guard (keys.advanced(by: position).pointee == KeyType(truncatingIfNeeded: key)) else { return .zero }

        return Int(values.advanced(by: position).pointee)
    }

    /**
     * Empty the Transition Table.
     */
    internal func reset() {
        keys.assign(repeating: .zero, count: Self.size)
        values.assign(repeating: .zero, count: Self.size)
    }
}
