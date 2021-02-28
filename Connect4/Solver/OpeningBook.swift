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
import Combine

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

        init(width: Int, height: Int, depth: Int, keySize: Int, valueSize: Int, log2Size: Int) {
            self.width = Int8(width)
            self.height = Int8(height)
            self.maxStoredPositionDepth = Int8(depth)
            self.keySize = Int8(keySize)
            self.valueSize = Int8(valueSize)
            self.logSize = Int8(log2Size)
        }
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

//        let headerData: OpenBookHeaderFormat
//        UnsafeMutablePointer(&headerData).withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<OpenBookHeaderFormat>.size) { memory in
//            rawData.copyBytes(to: memory, count: MemoryLayout<OpenBookHeaderFormat>.size)
//        }

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

        var header = OpenBookHeaderFormat(width: width,
                                          height: height,
                                          depth: depth,
                                          keySize: transpositionTable?.partialKeySize ?? 0,
                                          valueSize: transpositionTable?.valueSize ?? 0,
                                          log2Size: transpositionTable?.log2Size ?? 0
        )
        let headerData = Data(bytes: &header,
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

        if (visited.count % 10000000) == 0 {
            print("\(Date()): \(visited.count)")
        }

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

extension OpeningBook {
    public func information() {
        print("Width x Height: \(width) x \(height)")
        print("Depth: \(depth)")

        let keySize = transpositionTable?.partialKeySize ?? 0
        let valueSize = transpositionTable?.valueSize ?? 0
        let log2Size = transpositionTable?.log2Size ?? 0
        print("Key and value size: \(keySize), \(valueSize)")
        print("Transposition table log2 size : \(log2Size)")


        let fillingRate = transpositionTable?.fillingRate ?? 0
        print(String(format: "Filling rate :  %.2f%%", fillingRate * 100))
    }

    public func generateLoadBalancing(bookSize: Int) {
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

        // set up visited nodes to empty
        var visited = Set<UInt>()
        var positions = Array<Position>()
        var key3s = Array<UInt>()

        // Exploration
        explore(position: Position(), visited: &visited) { position, key3 in
            positions.append(position)
            key3s.append(key3)
        }

        print("Generated entries : \(positions.count)")

        let group = DispatchGroup()

        // on découpe en autant de thraed que de cores
        let threads = ProcessInfo().activeProcessorCount

        // unité de traitement
        let unit = LoadBalancer(positions: positions)

        // on lance le traitement sur chaque core
        for queue in 0..<threads {

            // init Solver
            let solverQueue = DispatchQueue(label:"Solver \(queue)", qos: .utility)

            group.enter()
            solverQueue.async {
                self.computeScore(processing: unit,
                                  queue: solverQueue)
                group.leave()
            }
        }

        group.wait()

        print("\(Date()) Creating Transposition Table.")

        // insert into transposition table
        for index in 0..<key3s.count {
            transpositionTable?.put(key: key3s[index],
                                    value: unit.scores[index] - Solver.Score.minScore + 1)
        }
    }

    internal func computeScore(processing unit: LoadBalancer, queue: DispatchQueue) {
        // init Solver
        let solver = Solver()

        while let task = unit.next() {

            // init score
            var scores = [Int]()

            for position in task.positions {
                let score = solver.solve(position: position, weak: false)
                scores.append(score)
            }

            unit.setResult(task: task, value: scores)

            print("\(Date()) computed \(scores.count) positions on queue \(queue.label)")
        }
    }
}

internal class LoadBalancer {
    let positions: Array<Position>
    var scores: Array<Int>

    private let batchSize : Int
    private var nextBatchIndex: Int = 0
    private var semaphore = DispatchSemaphore(value: 1)

    init(positions: Array<Position>) {
        self.positions = positions
        self.scores = Array<Int>(repeating: .zero, count: positions.count)
        self.batchSize = clamp(positions.count / ProcessInfo().activeProcessorCount / 100,
                               minValue: 1,
                               maxValue: 50000)

        print("batch size is \(batchSize)")
    }

    func next() -> Task? {
        // Wait semaphore is accessible
        semaphore.wait()
        defer {
            semaphore.signal()
        }

        // if index reaches end of positions : no more task.
        guard nextBatchIndex < positions.count else { return nil }

        // compute range
        let rangeMin = nextBatchIndex
        let rangeMax = min (nextBatchIndex + batchSize, positions.count)
        let range = rangeMin..<rangeMax

        // set next batch index value
        nextBatchIndex = rangeMax

        return Task(range: range, positions: positions)
    }

    func setResult(task: Task, value: [Int]) {
        precondition(task.range.count == value.count, "scores doesn't fit in range")
        semaphore.wait()
        scores.replaceSubrange(task.range, with: value)
        semaphore.signal()
    }
}

internal struct Task {
    let range: Range<Int>
    let positions: [Position]

    init(range: Range<Int>, positions: [Position]) {
        self.range = range
        self.positions = Array(positions[range])
    }
}

public func clamp<T>(_ value: T, minValue: T, maxValue: T) -> T where T : Comparable {
    return min(max(value, minValue), maxValue)
}
