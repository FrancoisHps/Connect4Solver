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

extension BinaryInteger {
    /**
     * Next prime number greater than or equal to that value.
     * Value must be >= 2
     */
    public var nextPrime : Self {
        assert(self >= 2)
        return hasFactor(min: 2, max: self) ? (self + 1).nextPrime : self
    }

    /**
     * Tells if a value has a a divisor between min (inclusive) and max (exclusive)
     * - parameter min: lower bound
     * - parameter max: upper bound
     * - returns: Returns true if this value has a divisor greater or equal than min and lower than max, and false otherwise.
     */
    public func hasFactor(min: Self, max: Self) -> Bool {
        guard min * min <= self else { return false }
        guard min + 1 < max else { return isMultiple(of: min) }

        return hasFactor(min: min, max: med(min, max)) || hasFactor(min: med(min, max), max: max)
    }
}

/**
 * medium between min and max
 */
public func med<T: BinaryInteger>(_ min: T, _ max: T) -> T {
    (min + max) / 2
}
