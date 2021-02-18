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

public class OpeningBook {

    private var transpositionTable: TranspositionTableProtocol?
    private let width: Int
    private let height: Int
    private var depth: Int

    enum OpeningBookError: Error {
        case missingHeaderData
        case invalidWidth
        case invalidHeight
        case invalidDepth
        case invalidKeySize
        case invalidValueSize
        case invalidLog2Size
        case missingData
        case unimplementedSize
    }

    private struct OpenBookHeaderFormat {       // il faudrait pouvoir le lire directement....
        let width: Int8
        let height: Int8
        let maxStoredPositionDepth: Int8
        let keySize: Int8
        let valueSize: Int8
        let logSize: Int8
    }

    public init(width: Int, height: Int, depth: Int) {
        self.width = width
        self.height = height
        self.depth = depth
        self.transpositionTable = nil
    }

    public convenience init?(width: Int, height: Int, openingBook name: String) {
        self.init(width: width, height: height, depth: -1)
        do {
            try load(fileName: name)
        }
        catch {
            return nil
        }
    }

    private func load(fileName: String) throws {
        let url = URL(fileURLWithPath: "./\(fileName).book")
        let rawData = try Data(contentsOf: url)

        guard rawData.count >= MemoryLayout<OpenBookHeaderFormat>.size else {
            throw Self.OpeningBookError.missingHeaderData
        }

        let width = Int(rawData[0])     // lire directement la structure....
        let height = Int(rawData[1])
        let maxStoredPositionDepth = rawData[2]
        let keySize = rawData[3]
        let valueSize = rawData[4]
        let logSize = Int(rawData[5])

        guard width == self.width else { throw OpeningBookError.invalidWidth }
        guard height == self.height else { throw OpeningBookError.invalidHeight }
        guard maxStoredPositionDepth <= width * height else { throw OpeningBookError.invalidDepth }
        guard keySize <= 8 else { throw OpeningBookError.invalidKeySize }
        guard valueSize == 1 else { throw OpeningBookError.invalidValueSize }
        guard logSize <= 40 else { throw OpeningBookError.invalidLog2Size }

        let size = (1 << logSize).nextPrime
        guard rawData.count == MemoryLayout<OpenBookHeaderFormat>.size + Int(keySize + valueSize) * size else {
            throw Self.OpeningBookError.missingData
        }

        switch (keySize, valueSize) {
            case (1, 1):
                self.transpositionTable = GenericTranspositionTable<UInt8, Int8>.init(logSize: logSize, data: rawData, from: 6)
            case (2, 1):
                self.transpositionTable = GenericTranspositionTable<UInt16, Int8>.init(logSize: logSize, data: rawData, from: 6)
            case (4, 1):
                self.transpositionTable = GenericTranspositionTable<UInt32, Int8>.init(logSize: logSize, data: rawData, from: 6)

            default:
                throw Self.OpeningBookError.unimplementedSize
        }

        self.depth = Int(maxStoredPositionDepth)
    }

    public func save(fileName: String) throws {
        let url = URL(fileURLWithPath: "./\(fileName).book")

        var header = OpenBookHeaderFormat(
            width: Int8(width),
            height: Int8(height),
            maxStoredPositionDepth: Int8(depth),
            keySize: Int8(transpositionTable?.partialKeySize ?? 0),
            valueSize: Int8(transpositionTable?.valueSize ?? 0),
            logSize: Int8(transpositionTable?.log2Size ?? 0)
        )

        let headerData = Data(bytes: UnsafeRawPointer(&header),
                              count: MemoryLayout<OpenBookHeaderFormat>.size)

        guard let transpo = transpositionTable?.data else { throw OpeningBookError.missingData }
        let datas = headerData + transpo
        try datas.write(to: url)
    }

    /**
     * Explore and print all possible position under a given depth.
     * symetric positions are printed only once.
     */
    public func explore(position: Position, moves: String, visited: inout Set<UInt>, depth: Int) {
        // virer depth : déjà dans les membres

        let key = position.key3

        // already explored position
        guard !visited.contains(key) else { return }

        // flag new position as visited
        visited.insert(key)

        // AJOUTER CE MOVE
        print(moves)

        // do not explore at further depth
        guard position.numberOfMoves < depth else { return }

        // explore all possible moves
        for column in 0..<width {
            if (position.canPlay(in: column) && !position.isWinnngMove(in: column)) {
                var position2 = position
                position2.play(in: column)
                explore(position: position2, moves: moves + "\(column + 1)", visited: &visited, depth: depth)
            }
        }
    }

    /**
     * Explore all possible position under a given depth and execute the closure.
     * Closure on symetric positions are executed only once.
     */
    public func explore(position: Position, visited: inout Set<UInt>, _ use: (Position, UInt) -> ()) {
        // compute key3
        let key = position.key3

        // already explored position
        guard !visited.contains(key) else { return }

        // flag new position as visited
        visited.insert(key)

        // call the closure with position and key
        use(position, key)

        // do not explore at further depth
        guard position.numberOfMoves < depth else { return }

        // explore all possible moves
        for column in 0..<width {
            if (position.canPlay(in: column) && !position.isWinnngMove(in: column)) {
                var position2 = position
                position2.play(in: column)
                explore(position: position2, visited: &visited, use)
            }
        }
    }

    public func generate(bookSize: Int) {
        // calculer la taille de la key..... value toujours Int8
        let keySize = Int(Double(depth + width - 1) * log2(3.0)) + 1 - bookSize

        // a noter keySize en bits
        // si <= 0 pas besoin de stocker la key (suffisamment d'entreés pour être distincts !)

        switch keySize {
            case ...8 :
                self.transpositionTable = GenericTranspositionTable<UInt8, Int8>.init(logSize: bookSize)
            case 9...16:
                self.transpositionTable = GenericTranspositionTable<UInt16, Int8>.init(logSize: bookSize)
            case 17...32:
                self.transpositionTable = GenericTranspositionTable<UInt32, Int8>.init(logSize: bookSize)
            default:
                self.transpositionTable = nil // error.
        }

        // init Solver
        let solver = Solver()

        // set up visited nodes to empty
        var visited = Set<UInt>()

        // Exploration
        explore(position: Position(), visited: &visited) { position, key3 in
            let score = solver.solve(position: position, weak: false)
            transpositionTable?.put(key: key3, value: score - Solver.Score.minScore + 1)
        }
    }

    /**
     * Get the value of a key
     * - parameter position: must be less than key_size bits.
     * - returns: value_size bits value associated with the key if present, 0 otherwise.
     */
    internal func get(position: Position) -> Int {
        guard position.numberOfMoves <= depth else { return 0 }

        return transpositionTable?.get(key: position.key3) ?? 0
    }
}
