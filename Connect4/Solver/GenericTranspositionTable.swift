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

internal protocol TranspositionTableProtocol {

    init(logSize: Int)

    func put(key: UInt, value: Int)
    func get(key: UInt) -> Int
    func reset()

    var partialKeySize: Int { get }
    var valueSize: Int { get }
    var log2Size: Int { get }

    var data: Data { get }

    var fillingRate: Double { get }
}

/**
 * Transposition Table is a simple hash map with fixed storage size.
 * In case of collision we keep the last entry and overide the previous one.
 * This is the swift generic version;
 * In swift we can't construct generic with parameter (like log_size) neiher
 * use something like constexpr.
 * This class will be slower tha his non generic counter part
 * But useful in opening book.
 */
final internal class GenericTranspositionTable<PartialKey: UnsignedInteger, Value: FixedWidthInteger> : TranspositionTableProtocol {

    private var keys : UnsafeMutablePointer<PartialKey>
    private var values : UnsafeMutablePointer<Value>
    private var size : Int

    /// partial key size in byte
    var partialKeySize : Int { MemoryLayout<PartialKey>.size }

    /// value size in byte
    var valueSize : Int { MemoryLayout<Value>.size }

    /// log2(number of entries in transposition table)
    var log2Size : Int { Int(log2(Double(size))) }


    /**
     * Allocate and initialize to zero a mutable pointer.
     * We don't use UnsafeMutableBufferPointer because we don't need collection protocol
     * We'll store a 56 bit key in low bytes  and an 8 bit value in high byte
     * - parameter size: number of entries
     */
    internal init(logSize: Int) {
        size = (1 << logSize).nextPrime
        keys = UnsafeMutablePointer<PartialKey>.allocate(capacity: size)
        keys.initialize(repeating: .zero, count: size)
        values = UnsafeMutablePointer<Value>.allocate(capacity: size)
        values.initialize(repeating: .zero, count: size)
    }

    deinit {
        keys.deallocate()
        values.deallocate()
    }

    /**
     * Compute the index in the transition table for the given key.
     */
    private func index(for key: UInt) -> Int {
        Int(bitPattern: key) % size
    }

    /**
     * Store a value for a given key
     * - parameter key: must be less than key_size bits.
     * - parameter value: must be less than value_size bits. null (0) value is used to encode missing data
     */
    internal func put(key: UInt, value: Int) {
        assert(value <= Value.max)
        assert(value >= Value.min)

        let position = index(for: key)

        keys.advanced(by: position).pointee = PartialKey(truncatingIfNeeded: key)
        values.advanced(by: position).pointee = Value(truncatingIfNeeded: value)
    }

    /**
     * Get the value of a key
     * - parameter key: must be less than key_size bits.
     * - returns: value_size bits value associated with the key if present, 0 otherwise.
     */
    internal func get(key: UInt) -> Int {
        let position = index(for: key)

        guard (keys.advanced(by: position).pointee == PartialKey(truncatingIfNeeded: key)) else { return .zero }

        return Int(values.advanced(by: position).pointee)
    }

    /**
     * Empty the Transition Table.
     */
    internal func reset() {
        keys.assign(repeating: .zero, count: size)
        values.assign(repeating: .zero, count: size)
    }

    /**
     * Serialization / Deserialization
     */
    public var data : Data {
        let keyData = Data(bytes: keys, count: size)
        let valueData = Data(bytes: values, count: size)
        return keyData + valueData
    }

    internal convenience init(logSize: Int, data: Data, from startIndex: Int) {
        self.init(logSize: logSize)

        let keysData = data[startIndex...]
        keys.withMemoryRebound(to: UInt8.self, capacity: partialKeySize) { memory in
            keysData.copyBytes(to: memory, count: partialKeySize * size)
        }

        let valuesData = data[(startIndex + partialKeySize * size)...]
        values.withMemoryRebound(to: UInt8.self, capacity: valueSize) { memory in
            valuesData.copyBytes(to: memory, count: valueSize * size)
        }
    }
}

extension GenericTranspositionTable {
    var fillingRate: Double {
        var filling = 0

        for index in 0..<size {
            if (keys[index] != 0 && values[index] != 0) {
                filling += 1
            }
        }

        return Double(filling) / Double(size)
    }
}
