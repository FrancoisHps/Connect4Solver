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

    /// public initializer
    public init() {
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

        // increment counter of explored nodes
        nodeCount += 1

        // check for draw game
        guard !position.draw else { return 0 }

        // check if current player can win next move
        for column in 0..<Position.Dimension.width {
            if position.canPlay(in: column) && position.isWinnngMove(in: column) {
                return (Position.Dimension.area + 1 - position.numberOfMoves) / 2
            }
        }

        // upper bound of our score as we cannot win immediately
        let max = (Position.Dimension.area - 1 - position.numberOfMoves) / 2
        if (beta > max) {
            // there is no need to keep beta above our max possible score.
            beta = max

            // prune the exploration if the [alpha;beta] window is empty.
            if alpha >= beta {
                return beta
            }
        }

        // compute the score of all possible next move and keep the best one
        for column in 0..<Position.Dimension.width {
            if position.canPlay(in: column) {
                let position2 = Position(position: position)

                // It's opponent turn in position2 position after current player plays x column.
                position2.play(in: column)

                // If current player plays col x, his score will be the opposite of opponent's score after playing col x
                let score = -negamax(position: position2, alpha: -beta,beta: -alpha)

                // prune the exploration if we find a possible move better than what we were
                if score >= beta {
                    return score
                }

                // reduce the [alpha;beta] window for next exploration, as we only
                // need to search for a position that is better than the best so far.
                if score > alpha {
                    alpha = score
                }
            }
        }

        return alpha;
    }

    /**
     Entry point to solve a connect 4 position
     - parameter position: actual position to be solved
     - parameter weak : if true, only tells you the win/draw/loss outcome of the position, otherwise, it will tell you
     the score taking into account the number of moves before the end of the game
     */
    public func solve(position: Position, weak: Bool = false) -> Int {
        nodeCount = 0;
        return weak ?
            // Use a [-1;1] score window to look only for win/draw/loss
            negamax(position: position, alpha: -1, beta: 1)
            :
            negamax(position: position, alpha: -Position.Dimension.area / 2, beta: Position.Dimension.area / 2);
    }
}
