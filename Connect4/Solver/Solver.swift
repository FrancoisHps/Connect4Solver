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
 A class to solve Connect 4 position using Negamax variant of min-max algorithm.
 */
public final class Solver {
    /// counter of explored nodes.
    public var nodeCount : Int = 0

    /// column exploration order : center first, edge last
    internal let columnOrder : [Int]

    /// transposition table
    private var transpositionTable : TranspositionTable

    /// define min and max score
    struct Score {
        static let minScore = -(Position.Dimension.area) / 2 + 3;
        static let maxScore = (Position.Dimension.area + 1) / 2 - 3;
    }

    /// public initializer
    public init() {
        // initialize the columnOrder array : center columns first and edge columns at the end
        columnOrder = (0..<Position.Dimension.width).map { index in
            Position.Dimension.width / 2 + (1 - 2 * (index % 2)) * (index + 1) / 2
        }.reversed()

        // fixed transpostion table size
        transpositionTable = TranspositionTable()
    }

    /**
     Recursively solve a connect 4 position using negamax variant of alpha-beta algorithm.
     - parameter position: actual position to be solved
     - parameter alpha: lower bound score
     - parameter beta: upper bound score
     - returns: the exact score, an upper or lower bound score depending of the case:
     - if true score of position <= alpha then true score <= return value <= alpha
     - if true score of position >= beta then beta <= return value <= true score
     - if alpha <= true score <= beta then return value = true score
     */
    private func negamax(position: Position, alpha : Int, beta: Int) -> Int {
        var alpha = alpha
        var beta = beta
        assert(alpha < beta)
        assert(!position.canWinNext)

        // increment counter of explored nodes
        nodeCount += 1

        // check for possible non loosing moves
        let next = position.possibleNonLoosingMoves;
        if next == 0 {
            // if no possible non losing move, opponent wins next move
            return -(Position.Dimension.area - position.numberOfMoves) / 2
        }

        // check for draw game
        if position.draw { return 0 }

        // lower bound of score as opponent cannot win next move
        var min = -(Position.Dimension.area - 2 - position.numberOfMoves) / 2
        if(alpha < min) {
            // there is no need to keep beta above our max possible score.
            alpha = min;

            if(alpha >= beta) {
                // prune the exploration if the [alpha;beta] window is empty.
                return alpha;
            }
        }

        // upper bound of our score as we cannot win immediately
        var max = (Position.Dimension.width * Position.Dimension.height - 1 - position.numberOfMoves) / 2
        if (beta > max) {
            // there is no need to keep beta above our max possible score.
            beta = max

            // prune the exploration if the [alpha;beta] window is empty.
            if alpha >= beta {
                return beta
            }
        }

        // check into transposition table
        let key  = position.key
        let value = transpositionTable.get(key: key)
        if value != 0 {
            if (value > Score.maxScore - Score.minScore + 1) {
                // we have an lower bound
                min = value + 2 * Score.minScore - Score.maxScore - 2
                if(alpha < min) {
                    // there is no need to keep beta above our max possible score.
                    alpha = min;

                    if(alpha >= beta) {
                        // prune the exploration if the [alpha;beta] window is empty.
                        return alpha;
                    }
                }
            }
            else {
                // we have an upper bound
                max = value + Score.minScore - 1
                if (beta > max) {
                    // there is no need to keep beta above our max possible score.
                    beta = max

                    // prune the exploration if the [alpha;beta] window is empty.
                    if alpha >= beta {
                        return beta
                    }
                }
            }
        }

        // sort all possible moves
        var moves = MoveSorter(at: position.numberOfMoves)
        for index in 0..<Position.Dimension.width {
            let move = next & Position.columnMask(for: columnOrder[index])
            if move != 0 {
                moves.add(move: move, score: position.moveScore(move: move))
            }
        }

        // compute the score of all possible next move and keep the best one
        for next in moves {
            var position2 = position

            // It's opponent turn in position2 position after current player plays x column.
            position2.play(move: next)

            // If current player plays col x, his score will be the opposite of opponent's score after playing col x
            let score = -negamax(position: position2, alpha: -beta,beta: -alpha)

            // prune the exploration if we find a possible move better than what we were
            if score >= beta {
                // save the lower bound of the position
                transpositionTable.put(key: position.key, value: score +  Score.maxScore - 2 * Score.minScore + 2)

                return score
            }

            // reduce the [alpha;beta] window for next exploration, as we only
            // need to search for a position that is better than the best so far.
            if score > alpha {
                alpha = score
            }
        }

        // save the upper bound of the position
        transpositionTable.put(key: position.key, value: alpha - Score.minScore + 1)

        return alpha;
    }

    /// reset solver to solve another position
    public func reset() {
        nodeCount = 0
        transpositionTable.reset()
    }

    /**
     Entry point to solve a connect 4 position
     - parameter position: actual position to be solved
     - parameter weak : if true, only tells you the win/draw/loss outcome of the position, otherwise, it will tell you
     the score taking into account the number of moves before the end of the game

     This function combined two different techniques :
     - Iterative deepening : increasing iteratively the depth of search while keeping shallow search results in transposition table.
     - Null window search : using [alpha; beta] window of minimal size (beta = alpha+1) to get faster lower or upper bound of the score.
     */
    public func solve(position: Position, weak: Bool = false) -> Int {
        var min = weak ? -1 : -(Position.Dimension.area - position.numberOfMoves)/2
        var max = weak ?  1 :  (Position.Dimension.area + 1 - position.numberOfMoves)/2

        // Iterative Deepening : iteratively narrow the min-max exploration window
        while(min < max) {
            var med = min + (max - min)/2
            if (med <= 0 && min / 2 < med) {
                med = min / 2
            }
            else if (med >= 0 && max / 2 > med) {
                med = max / 2
            }

            // use a null depth window to know if the actual score is greater or smaller than med
            let r = negamax(position: position, alpha: med, beta: med + 1);

            if(r <= med) {
                max = r;
            }
            else {
                min = r
            }
        }

        return min
    }

    // MARK: - Analyze

    /**
     * Returns the score off all possible moves of a position as an array.
     * Returns nil for unplayable columns
     * - parameter position: actual position to be analyzed
     * - parameter weak : if true, only tells you the win/draw/loss outcome of the position, otherwise, best score best move
     */
    public func analyze(position: Position, weak: Bool) -> [Int?] {
        var scores = Array<Int?>(repeating: nil, count: Position.Dimension.width)
        for column in 0..<Position.Dimension.width {
            if position.canPlay(in: column) {
                if position.isWinnngMove(in: column) {
                    scores[column] = (Position.Dimension.area + 1 - position.numberOfMoves) / 2
                }
                else {
                    var position2 = position
                    position2.play(in: column)
                    scores[column] = -solve(position: position2, weak: weak);
                }
            }
        }

        return scores
    }
}
