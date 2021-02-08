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

    /// public initilizert
    public init() {
    }

    /**
     Recursively solve a connect 4 position using negamax variant of min-max algorithm.
     - parameter position: actual position to be solved
     - returns: the score of a position:
     - 0 for a draw game
     - positive score if you can win whatever your opponent is playing. Your score is
     the number of moves before the end you can win (the faster you win, the higher your score)
     - negative score if your opponent can force you to lose. Your score is the oposite of
     the number of moves before the end you will lose (the faster you lose, the lower your score).
     */
    private func negamax(position: Position) -> Int {
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

        // init the best possible score with a lower bound of score.
         var bestScore = -Position.Dimension.area

        // compute the score of all possible next move and keep the best one
        for column in 0..<Position.Dimension.width {
            if position.canPlay(in: column) {
                let position2 = Position(position: position)

                // It's opponent turn in position2 position after current player plays x column.
                position2.play(in: column)

                // If current player plays col x, his score will be the opposite of opponent's score after playing col x
                let score = -negamax(position: position2)

                // keep track of best possible score so far.
                if(score > bestScore)  {
                    bestScore = score
                }
            }
        }

        return bestScore;
    }
    
    /**
     Entry point to solve a connect 4 position
     - parameter position: actual position to be solved
     */
    public func solve(position: Position) -> Int {
        nodeCount = 0;
        return negamax(position: position);
    }
}


