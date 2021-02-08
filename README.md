# Connect4 Game Solver

This project is my swift adapation of [Connect4 Game Solver](http://connect4.gamesolver.org) by [Pascal Pons](mailto:contact@gamesolver.org?subject=Connect4%20Game%20Solver)

## Build a perfect swift connect4 solver

I follow each step of the Pascal Pons C tutorial, and I try to port C code to swift code to be as efficient as possible. Please feel free to send me your comments or improvements on this tutorial.

Swift source code is provided under the [GNU affero GLP licence](https://www.gnu.org/licenses/agpl-3.0.en.html).

### Test protocol

Position's notation, position's score and benchmarking are available on [gamesolver blog](http://blog.gamesolver.org/solving-connect-four/02-test-protocol/).

To help using test set, I created a Collection class named BenchmarkDataSet, which contains the 6 tests set, each of them containg 1000 test cases. 

|Test Set (1000 test cases each)  | Test Set name | Test Set Index |
|:------------------------------- |:--------------| --------------:|
| Test\_L3_R1                     | End-Easy      | 0              |
| Test\_L2_R1                     | Middle-Easy   | 1              |
| Test\_L2_R2                     | Middle-Medium | 2              |
| Test\_L1_R1                     | Begin-Easy    | 3              |
| Test\_L2_R2                     | Begin-Medium  | 4              |
| Test\_L2_R3                     | Begin-Hard    | 5              |


Usage :

    let datSet = BenchmarkDataSet(index: 0)
    for position in datSet {
    	let notation = position.line
    	let board = position.position
    	let score = position.score
    }

### MinMax algorithm

MinMax algorithm explanations are available on [gamesolver blog](http://blog.gamesolver.org/solving-connect-four/03-minmax/).

Swift solution is implemented using native swift arrays. This is not a very efficient solution, as swift version is about 14 time slower than C version on the same computer.

Position swift declaration :

	public enum Chip : Int, CaseIterable {
	   case none, player1, player2
	}

	public final class Position {

	    // Dimension of Connect4 Position
	    struct Dimension {
	        static let width = 7
	        static let height = 6
	        static let area = width * height
	    }
	
	    /// Board
	    private var board : [Chip]
	
	    /// Number of stones per column
	    private var height : [Int]
	
	    /// Number of moves played since the beinning of the game.
	    public var numberOfMoves = 0
	}


### Alpha-beta algorithm algorithm

Alpha-beta algorithm explanations are available on [gamesolver blog](http://blog.gamesolver.org/solving-connect-four/04-alphabeta/).

Swift solution uses the same position class as in MinMax algorithm. The solution is better but still inefficient compared to C's version.

### Move exploration order

We try to optimize the algorithm by exploring best nodes first. As allways, explanations are available on [gamesolver blog](http://blog.gamesolver.org/solving-connect-four/05-move-exploration-order/).

One more time, the solution is better but still inefficient compared to C's version.

### Bitboard

Instead of using an array to store the position, we use a bitmap to encode positions as explained on [gamesolver blog](http://blog.gamesolver.org/solving-connect-four/06-bitboard/).

The game is now encoded with only three 64 bits Integer. In swift instead of using a class, we now use a struct.

Position swift declaration :

	public struct Position {
	
	    // Dimension of Connect4 Position
	    struct Dimension {
	        static let width = 7
	        static let height = 6
	        static let area = width * height
	    }
	
	    /// Binary bitboard representation : 1 on stones of current player
	    private var currentPosition : UInt
	
	    /// Binary bitboard representation : 1 on any color stones
	    private var mask : UInt
	
	    /// Number of moves played since the beginning of the game.
	    public var numberOfMoves : Int
	 }
	 
Structs are value types stored in the stack, which is more efficient that the heap used for classes. Thus the Bitboard version is about 15 times faster than the previous version. This is a great ehancement !

### Transposition Table

Transposition table is used to save time by caching the outcome of previous computation. Full explanations can be found on [gamesolver blog](http://blog.gamesolver.org/solving-connect-four/07-transposition-table/).

As we've seen in first part of this tutorial, native swift arrays are inefficient for intensive usage. In order to use the full power of transposition table we need to implement it using [unsafe swift](https://developer.apple.com/videos/play/wwdc2020/10648/). 

Transposition table stores an array of 64 bits unsigned integer (56 bits to encode the key, and 8 bits to encode the score of the given position). Transposition table is a typed, write access array, so we use an UnsafeMutablePointer of UInt.

If you're having trouble choosing the right unsafe swift pointer, have a look at this excellent [Raywenderlich.com article](https://www.raywenderlich.com/7181017-unsafe-swift-using-pointers-and-interacting-with-c).

Swift implementation of the transposition table :

	final internal class TranspositionTable {
	
	   private var table : UnsafeMutablePointer<UInt>
	   private var size : Int
	
	   init(size: Int) {
	      self.size = size
	      table = UnsafeMutablePointer<UInt>.allocate(capacity: size)
	      table.initialize(repeating: .zero, count: size)
	   }
	}

Accessing data is less intutive tha with array :

	let value = table.advanced(by: position).pointee // value = table[position]
	table.advanced(by: position).pointee = newValue  // table[position] = newValue

You also must keep in mind that swift is strongly typed. To compute an Int index from an UInt key, we have to rebound the value using Int(bitPattern:).

	private func index(for key: UInt) -> Int {
      Int(bitPattern: key) % size
	}
	
This way, our swift transposition table is as efficient as his C counterpart.

### Iterative Deepening & Null Window

Iterative Deepening & Null Window algorithm explanations are available on [gamesolver blog](http://blog.gamesolver.org/solving-connect-four/08-iterative-deepening/).

C code is trivial to port into Swift.

### Anticipate direct losing moves

Explanations are available on [gamesolver blog](http://blog.gamesolver.org/solving-connect-four/09-anticipate-losing-moves/).

This ehancement is also trivial to port into Swift.

### Better move ordering

This time we take into account the moves that are creating alignment opportunities. See full explanations on [gamesolver blog](http://blog.gamesolver.org/solving-connect-four/10-better-move-ordering/).

This algorithm rely on MoveSorter class which is implemented with an array on C version. Allocating and desallocating MoveSorter class for each position in Swift results in poor performance.

As with the transposition table, we'll use unsafe Swift to build efficient MoveSorter object. 

To avoid multiple allocations / deallocations, as we work on only one position at a time, we use a pre allocated pool of MoveSorter.

    /// create a move sorter pool
    static private var moveSorterPool : UnsafeMutablePointer<Entry> =  {
        let size = Position.Dimension.area * Position.Dimension.width
        let pool = UnsafeMutablePointer<Entry>.allocate(capacity: size)
        return pool
    }()

When allocating a new MoveSorter we simply set the count to 0, and set the entries pointer to correct index.  

    /**
     * Initiate a moveSorter container
     * - parameter depth: Position in the saerch tree - we simply use numberOfMove. Must be between 0 and Position.Dimension.area - 1
     */
    internal init(at depth: Int) {
        entries = Self.moveSorterPool.advanced(by: depth * Position.Dimension.width)
        count = 0
    }

To iterate over the move sorter, we use the swift native iterative protocol by implementing next() function.

	extension MoveSorter : Sequence, IteratorProtocol {
	
	    /**
	     * Advances to the next element and returns it, or nil if no next element exists.
	     */
	    internal mutating func next() -> UInt? {
	        if count == 0 {
	            return nil
	        }
	        else {
	            count -= 1
	            return entries.advanced(by: count).pointee.move
	        }
	    }
	}

### Optimized transposition table

Using the chinese remainer theorem, we can store partial key. Explanations are available on [gamesolver blog](http://blog.gamesolver.org/solving-connect-four/11-optimized-transposition-table/).

We use two UnsafeMutablePointer : one for the 32 bits key, and another one for the 8 bits value. Thus transposition table only use 40MB instead of 64MB. We can access directly to the key and value without any bitwise operation.

Code is provided for standard Connect4 board (7 * 6). I haven't found a way to be as generic as C version. Suggestions are welcome.

### Lower bound transposition table

Explanations are available on [gamesolver blog](http://blog.gamesolver.org/solving-connect-four/12-lower-bound-transposition-table/).

This ehancement is trivial to port from C into Swift.


## Targets

### Connect4 Framework & Test

Framework contains all you need to build a solver. Test set are included.
Frameworks is provided with a test target.

### Connect4CLI

This target uses swift-argument-parser to read and interpret command line arguments.

To run Connect4CLI from XCode, use scheme to write arguments passed on launch.

#### Solve a specific position

To solve a specific position, enter connect4 position, and a string containing all moves.

	Connect4CLI position 7422341735647741166133573473242566
	
Except for the minmax algorithm you can use weak solver using weak option
	
	Connect4CLI position 7422341735647741166133573473242566 --weak

#### Solve each postions of a test set

To test all positions in a specific test set, enter connect4 test-set and the index of the test set as mentionned in the Test protocol paragraph.

	Connect4CLI test-set 1
	
Except for the minmax algorithm you can use weak solver using weak option
	
	Connect4CLI test-set 1 --weak
   
### Profile with Instruments

Both solver and test set solver are built with native logging which capture telemetry for performance analysis using the unified logging system.

Run Connect4CLI from XCode using Product/Profile. Choose "Logging" template, and just run.


## Benchmarking

Using Bitboard, swift is about 20% slower than his C counterpart on the same machine.


## License
FourInARowSolverPackage is available under the GNU Affero General Public License.
