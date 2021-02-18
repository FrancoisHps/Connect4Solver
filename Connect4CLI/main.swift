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
import ArgumentParser
import os.log
import Connect4

/**
 * main
 */
print ("Starting at \(Date())")
Connect4Solver.main()
print ("Finishing at \(Date())")


/**
  We define two commands: test-set and position
  - test-set : to benchmark an entire test set
  - position : to solve a specific position
*/
struct Connect4Solver: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Connect4 solver.",
        subcommands: [TestSet.self, Position.self, Explore.self, Generate.self])
}


/**
 Reads Connect4 position from command line argument
 Syntax : Connect4CLI position 1234

 Any invalid position (invalid sequence of move, or already won game)
 will generate an error message to standard output.

 Log position telemetry using the unified logging system.
 Use intrument to analyse datas
 */
extension Connect4Solver {
    struct Position: ParsableCommand {
        @Argument(help: "A sequence of the played columns.")
        var moves: String

        @Flag(help: "Wether to use weak solver or not.")
        var weak = false

        func run()  {

            guard let position = Connect4.Position(moves: moves) else {
                print ("Invalid position")
                return
            }

            let solver = Solver(openingBook: "7x6")

            let pointsOfInterest = OSLog(subsystem: "game.solver.connect4", category: .pointsOfInterest)
            os_signpost(.begin, log: pointsOfInterest, name: "Solver", "position %@", position.debugDescription)

            let begin = Date()
            let score = solver.solve(position: position, weak: weak)
            let duration = -begin.timeIntervalSinceNow

            os_signpost(.end, log: pointsOfInterest, name: "Solver", "score %d, nodes %d", score, solver.nodeCount)
            print ("duration : \(duration)s, explored \(solver.nodeCount) nodes, score: \(score)")
        }
    }
}

/**
 Reads Connect4 test set from command line argument.
 Syntax : Connect4CLI test-set 0

 Solves each position contained in the given test set.
 Compare the score with the expected one. Post a signpost event if different.

 Log each position telemetry using the unified logging system.
 Use intrument to analyse datas
 */
extension Connect4Solver {
    struct TestSet: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Test all positions in the given test set.")

        @Argument(help: "Choose a test set index between 0 and 5")
        var index: Int

        @Flag(help: "Wether to use weak solver or not.")
        var weak = false

        func validate() throws {
            guard (0..<6).contains(index) else {
                throw ValidationError("Test set must be between 0 and 5.")
            }
        }

        func run() {
            solve(testSet: index)
        }

        func solve(testSet index: Int)  {

            let solver = Solver(openingBook: "7x6")
            let testSet = BenchmarkDataSet(index: index)

            var totalDuration = 0.0
            var totalNode = 0

            let pointsOfInterest = OSLog(subsystem: "game.solver.connect4", category: .pointsOfInterest)

            for position in testSet {

                os_signpost(.begin, log: pointsOfInterest, name: "Solver", "position %@", position.moves)

                let begin = Date()

                let score = solver.solve(position: position.position, weak: weak)
                let duration = -begin.timeIntervalSinceNow
                if (!weak && score != position.score ) || (weak && score != position.score.signum()){
                    os_signpost(.event, log: pointsOfInterest, name: "Solver", "Score is %d, expected is %d", score, weak ? position.score : position.score.signum())
                }
                totalDuration += duration
                totalNode += solver.nodeCount

                os_signpost(.end, log: pointsOfInterest, name: "Solver", "nodes %d", solver.nodeCount)

                solver.reset()
            }

            print ("duration : \(totalDuration)s, explored \(totalNode) nodes, average nodes \(Double(totalNode) / Double(testSet.count))")
        }
    }
}

extension Connect4Solver {
    struct Explore: ParsableCommand {
        @Argument(help: "Choose a depth")
        var depth: Int

        func run() {
            var visited = Set<UInt>()
            let book = OpeningBook(width: 7, height: 6, depth: depth)
            book.explore(position: Connect4.Position(), moves: "", visited: &visited, depth: depth)
        }
    }
}

extension Connect4Solver {
    struct Generate: ParsableCommand {
        @Argument(help: "Choose a depth")
        var depth: Int

        func run() {
            let book = OpeningBook(width: 7, height: 6, depth: depth)
            book.generate(bookSize: 24)
            do {
                try book.save(fileName: "7x6_depth14")
            }
            catch {

            }
        }
    }
}
